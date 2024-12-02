//
//  Styling.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat) {
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: alpha)
    }

    convenience init(int: Int) {
        self.init(red: (int & 0xff0000) >> 16, green: (int & 0x00ff00) >> 8, blue: int & 0x0000ff, alpha: 1)
    }

    static var random: UIColor {
        return UIColor(int: Int.random(in: (0x0...0xffffff)))
    }

    static let brandPrimary = UIColor(Color.brandPrimary)

    static let brandRed = UIColor(named: "brandRed", in: .module, compatibleWith: nil)
    static let brandOrange = UIColor(named: "brandOrange", in: .module, compatibleWith: nil)
}

public extension Color {
    static let brandOrange = Color("brandOrange", bundle: .module)
    static let brandTeal = Color("brandTeal", bundle: .module)
    static let brandBlue = Color("brandBlue", bundle: .module)
    static let brandDarkBlue = Color("brandDarkBlue", bundle: .module)
    static let textSecondary = Color(light: .init(int: 0x979797), dark: .init(int: 0x979797))
    static let deepGray = Color(int: 0x484848)
    static let darkGray = Color(int: 0x1C1E21)

    init(int: Int, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((int & 0xff0000) >> 16) / 255,
            green: Double((int & 0x00ff00) >> 8) / 255,
            blue: Double(int & 0x0000ff) / 255,
            opacity: alpha
        )
    }
}

public extension Font {
    static var header: Font {
        return .system(size: 15, weight: .semibold)
    }

    static var smallHeader: Font {
        return .system(size: 13, weight: .semibold)
    }

    static var smallBody: Font {
        return .system(size: 13, weight: .semibold)
    }

    static var body: Font {
        return .system(size: 16)
    }
}

public extension UIColor {
    static let backgroundDiminished = UIColor(Color.backgroundDiminished)
    static let backgroundPrimary = UIColor.dynamicColor(light: .white, dark: .black)
    static let backgroundGray = UIColor(Color.backgroundGray)
    static let textPrimary = UIColor.dynamicColor(light: .black, dark: .white)
    static let textDiminished = UIColor(Color.textDiminished)

    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }
}

public extension Color {
    static let brandPrimary = Color(light: .init(int: 0x5D63FF), dark: .init(int: 0x5D63FF))
    static let brandPrimaryBackground = Color(light: .init(int: 0x1F0E57), dark: .init(int: 0x1F0E57))
    static let textPrimary = Color(UIColor.textPrimary)
    static let textDiminished = Color(light: .init(int: 0x646464), dark: .init(int: 0x979797))
    static let backgroundPrimary = Color(UIColor.backgroundPrimary)
    static let backgroundDiminished = Color(light: .init(int: 0xF4F3F3), dark: .init(int: 0x161616))

    static let borderGray = Color(light: .init(int: 0xD2D2D2), dark: .init(int: 0x484848))
    static let backgroundGray = Color(light: .init(int: 0xF4F3F3), dark: .init(int: 0x1C1E21))
    static let textTertiary = Color(light: .init(int: 0x484848), dark: .init(int: 0xD2D2D2))
    static let textFaded = Color(light: .init(int: 0x979797), dark: .init(int: 0x646464))

    static let fadedGray = Color.init(int: 0x646464)

    init(light: Color, dark: Color) {
        self.init(UIColor.dynamicColor(light: UIColor(light), dark: UIColor(dark)))
    }

    init(light: UIColor, dark: UIColor) {
        self.init(UIColor.dynamicColor(light: light, dark: dark))
    }
}
