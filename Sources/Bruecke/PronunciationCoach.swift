import Foundation
import AVFoundation
import Speech

@MainActor
final class PronunciationCoach: ObservableObject {
    enum Phase: Equatable {
        case idle
        case listening
        case result(score: Int, heard: String)
    }

    @Published var phase: Phase = .idle
    @Published var level: CGFloat = 0

    var isActive: Bool { phase != .idle }

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private var target = ""
    private var heard = ""
    private var stopWork: DispatchWorkItem?
    private var starting = false   // izin penceresi sırasında ikinci start()'ı engeller

    private var smoothed: CGFloat = 0
    private var lastEmitNanos: UInt64 = 0

    func start(target: String) {
        // Yeniden giriş koruması: bir oturum başlatılırken veya dinlenirken ikinci kez başlatma.
        // (Çökme nedeni: izin beklenirken çift dokunuş → aynı bus'a ikinci tap → yakalanamayan istisna.)
        // .result durumundan ("Tekrar" düğmesi) yeniden başlamaya izin verilir.
        guard !starting, phase != .listening else { return }
        cancel()           // varsa önceki oturumu güvenle söküp at
        starting = true
        self.target = target
        self.heard = ""
        self.smoothed = 0
        requestPermissions { [weak self] granted in
            guard let self else { return }
            if granted { self.beginListening() }
            else {
                self.starting = false
                self.phase = .result(score: 0, heard: "Mikrofon/konuşma izni gerekli")
            }
        }
    }

    func reset() {
        cancel()
        phase = .idle
        level = 0
    }

    private func requestPermissions(_ completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            AVCaptureDevice.requestAccess(for: .audio) { micGranted in
                DispatchQueue.main.async {
                    completion(speechStatus == .authorized && micGranted)
                }
            }
        }
    }

    private func beginListening() {
        // Her zaman önce eski durumu tamamen söküp at — idempotent başlangıç.
        stopWork?.cancel(); stopWork = nil
        teardownAudio()
        starting = false

        guard let recognizer, recognizer.isAvailable else {
            phase = .result(score: 0, heard: "Tanıma şu an kullanılamıyor")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            request.append(buffer)
            self?.updateLevel(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            teardownAudio()
            phase = .result(score: 0, heard: "Mikrofon başlatılamadı")
            return
        }

        phase = .listening
        task = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result else { return }
            let text = result.bestTranscription.formattedString
            DispatchQueue.main.async { self.heard = text }
        }

        let work = DispatchWorkItem { [weak self] in self?.finish() }
        stopWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: work)
    }

    private func updateLevel(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        var sum: Float = 0
        for i in stride(from: 0, to: count, by: 4) { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(max(1, count / 4)))
        let norm = min(1, CGFloat(rms) * 14)
        smoothed = smoothed * 0.75 + norm * 0.25

        let now = DispatchTime.now().uptimeNanoseconds
        if now &- lastEmitNanos < 55_000_000 { return }
        lastEmitNanos = now
        let value = smoothed
        DispatchQueue.main.async { [weak self] in self?.level = value }
    }

    private func finish() {
        stopWork = nil
        teardownAudio()
        level = 0
        let score = Self.similarity(heard, target)
        phase = .result(score: score, heard: heard.isEmpty ? "—" : heard)
    }

    private func cancel() {
        stopWork?.cancel(); stopWork = nil
        teardownAudio()
        starting = false
    }

    // Ses motorunu/tap'i/tanıma görevini güvenle ve idempotent biçimde söker.
    private func teardownAudio() {
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    deinit {
        // Görünüm ortadan kalkarsa bile kaynaklar serbest bırakılsın (güvenlik ağı).
        stopWork?.cancel()
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        request?.endAudio()
        task?.cancel()
    }

    static func similarity(_ a: String, _ b: String) -> Int {
        let s1 = normalize(a), s2 = normalize(b)
        guard !s1.isEmpty, !s2.isEmpty else { return 0 }
        if s1 == s2 { return 100 }
        if s1.contains(s2) || s2.contains(s1) { return 88 }
        let dist = levenshtein(Array(s1), Array(s2))
        let sim = 1.0 - Double(dist) / Double(max(s1.count, s2.count))
        return max(0, min(100, Int(sim * 100)))
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private static func levenshtein(_ x: [Character], _ y: [Character]) -> Int {
        guard !x.isEmpty else { return y.count }
        guard !y.isEmpty else { return x.count }
        var d = Array(0...y.count)
        for i in 1...x.count {
            var prev = d[0]
            d[0] = i
            for j in 1...y.count {
                let temp = d[j]
                d[j] = min(d[j] + 1, d[j - 1] + 1, prev + (x[i - 1] == y[j - 1] ? 0 : 1))
                prev = temp
            }
        }
        return d[y.count]
    }
}
