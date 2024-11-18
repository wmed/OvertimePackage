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

    static let brandPrimary = UIColor(red: 20/255.0, green: 25/255.0, blue: 35/255.0, alpha: 1)
    static let brandSecondary = UIColor(red: 255/255.0, green: 110/255.0, blue: 64/255.0, alpha: 1)

    static let brandRed = UIColor(named: "brandRed", in: .module, compatibleWith: nil)
    static let brandOrange = UIColor(named: "brandOrange", in: .module, compatibleWith: nil)
}

public extension Color {
    static let brandOrange = Color("brandOrange", bundle: .module)
    static let brandTeal = Color("brandTeal", bundle: .module)
    static let brandBlue = Color("brandBlue", bundle: .module)
    static let brandDarkBlue = Color("brandDarkBlue", bundle: .module)
    static let textSecondary = Color(int: 0x979797)
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
