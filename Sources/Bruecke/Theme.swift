import SwiftUI

// Uygulamanın renk dili tek yerde: artikel/tür renkleri her kartta ve listede
// aynı görünür. der mavi, die pembe, das yeşil.
enum Theme {
    static let blue = Color(red: 10/255, green: 132/255, blue: 1)
    static let pink = Color(red: 255/255, green: 55/255, blue: 95/255)
    static let green = Color(red: 40/255, green: 200/255, blue: 100/255)
    static let purple = Color(red: 150/255, green: 95/255, blue: 230/255)
    static let teal = Color(red: 40/255, green: 170/255, blue: 190/255)
    static let orange = Color(red: 235/255, green: 160/255, blue: 30/255)

    static func genderColor(_ gender: Gender) -> Color {
        switch gender {
        case .der: return blue
        case .die: return pink
        case .das: return green
        case .none: return blue
        }
    }

    // Kelime türü rozeti: metin + renk (isimlerde renk artikelden gelir).
    static func tag(for entry: WordEntry) -> (text: String, color: Color)? {
        switch entry.kind {
        case .noun:
            if entry.gender == .none { return ("isim", blue) }
            return (entry.gender.rawValue, genderColor(entry.gender))
        case .verb: return ("fiil", purple)
        case .adjective: return ("sıfat", teal)
        case .phrase: return ("cümle", .secondary)
        case .other: return entry.posLabel.isEmpty ? nil : (entry.posLabel, .secondary)
        }
    }
}
