//
//  GetHeightModifier.swift
//  Overtime
//
//  Created by Daniel Baldonado on 12/2/24.
//

import SwiftUI

public struct GetHeightModifier: ViewModifier {
    @Binding public var height: CGFloat

    public func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.clear
            }
        )
    }
}
