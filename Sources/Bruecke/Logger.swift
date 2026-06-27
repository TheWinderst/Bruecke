import Foundation

// Hata ayıklama günlüğü. GÜVENLİK: Buraya ASLA kullanıcının seçtiği metni veya pano
// içeriğini yazma — yalnızca durum/uzunluk bilgisi. Dosya, dünyaya açık /tmp yerine
// kullanıcının özel Caches klasöründe ve 0600 (yalnızca sahibi okur) izniyle tutulur.
let bruecheLogURL: URL = {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let dir = base.appendingPathComponent("Bruecke", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("bruecke.log")
}()

func alog(_ message: String) {
    let stamp = ISO8601DateFormatter().string(from: Date())
    let line = "\(stamp)  \(message)\n"
    guard let data = line.data(using: .utf8) else { return }
    if FileManager.default.fileExists(atPath: bruecheLogURL.path),
       let handle = try? FileHandle(forWritingTo: bruecheLogURL) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    } else {
        FileManager.default.createFile(atPath: bruecheLogURL.path, contents: data,
                                       attributes: [.posixPermissions: 0o600])
    }
}

func alogReset() {
    try? FileManager.default.removeItem(at: bruecheLogURL)
}
