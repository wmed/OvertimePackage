//
//  GetHeightModifier.swift
//  Overtime
//
//  Created by Daniel Baldonado on 12/2/24.
//

import SwiftUI

public extension View {
    func getHeight(_ height: Binding<CGFloat>) -> some View {
        return self.modifier(GetHeightModifier(height: height))
    }
}

struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat

    func body(content: Content) -> some View {
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
