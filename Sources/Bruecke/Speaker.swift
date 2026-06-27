import AVFoundation

@MainActor
final class Speaker {
    private let synth = AVSpeechSynthesizer()

    func germanVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "de-DE" }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
    }

    private func voice(_ identifier: String?) -> AVSpeechSynthesisVoice? {
        if let identifier, let v = AVSpeechSynthesisVoice(identifier: identifier) { return v }
        return AVSpeechSynthesisVoice(language: "de-DE")
    }

    func speak(_ text: String, voiceIdentifier: String? = nil, rate: Float = 0.5) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.voice = voice(voiceIdentifier)
        u.rate = rate
        synth.speak(u)
    }

    func speakSlow(_ text: String, voiceIdentifier: String? = nil) {
        speak(text, voiceIdentifier: voiceIdentifier, rate: 0.35)
    }

    func speakSyllables(_ text: String, voiceIdentifier: String? = nil) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let word = text.components(separatedBy: " ").last ?? text
        let parts = syllabify(word)
        for part in parts {
            let u = AVSpeechUtterance(string: part)
            u.voice = voice(voiceIdentifier)
            u.rate = 0.4
            u.postUtteranceDelay = 0.25
            synth.speak(u)
        }
    }

    private func syllabify(_ word: String) -> [String] {
        let chars = Array(word.lowercased())
        let orig = Array(word)
        let n = chars.count
        let vowels = Set("aeiouäöüy")
        func isV(_ i: Int) -> Bool { i >= 0 && i < n && vowels.contains(chars[i]) }

        var cuts: [Int] = []
        var i = 0
        while i < n {
            if isV(i) {
                var j = i
                while j < n && isV(j) { j += 1 }
                var k = j
                while k < n && !isV(k) { k += 1 }
                if k < n {
                    let consCount = k - j
                    let boundary = consCount <= 1 ? j : j + (consCount - 1)
                    if boundary > 0 && boundary < n { cuts.append(boundary) }
                    i = boundary
                } else {
                    break
                }
            } else {
                i += 1
            }
        }

        guard !cuts.isEmpty else { return [word] }
        var result: [String] = []
        var prev = 0
        for c in cuts where c > prev {
            result.append(String(orig[prev..<c]))
            prev = c
        }
        if prev < n { result.append(String(orig[prev..<n])) }
        return result.isEmpty ? [word] : result
    }
}
