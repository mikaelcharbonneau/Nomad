//
//  NomadTheme.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

enum NomadTheme {
    static let offWhite = Color(red: 248/255, green: 249/255, blue: 250/255)
    static let darkText = Color(red: 26/255, green: 26/255, blue: 26/255)
    static let lightGrey = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let darkGreen = Color(red: 27/255, green: 82/255, blue: 72/255)
    static let lightGreen = Color(red: 194/255, green: 212/255, blue: 187/255)
    static let pillRadius: CGFloat = 30
    static let cardShadow: CGFloat = 20

    static var greeting: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 1: return "Happy Sunday!"
        case 7: return "Good weekend!"
        case 6: return "Happy Friday!"
        default:
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 12 { return "Good morning!" }
            else if hour < 17 { return "Good afternoon!" }
            else { return "Good evening!" }
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    let filled: Bool
    let color: Color

    init(filled: Bool = true, color: Color = .black) {
        self.filled = filled
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(filled ? color : .clear, in: .capsule)
            .foregroundStyle(filled ? .white : color)
            .overlay { Capsule().stroke(color, lineWidth: filled ? 0 : 1.5) }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}
