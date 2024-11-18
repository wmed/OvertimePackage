//
//  SplashView.swift
//  
//
//  Created by Daniel Baldonado on 10/3/24.
//

import SwiftUI

public struct SplashViewConfig {
    public var image: UIImage?
    public var radialTintColor: Color?
    public var imageTintColor: Color?
    public var backgroundColor: Color?

    public init(image: UIImage? = nil, 
                radialTintColor: Color? = nil,
                imageTintColor: Color? = nil,
                backgroundColor: Color? = nil) {
        self.image = image
        self.radialTintColor = radialTintColor
        self.imageTintColor = imageTintColor
        self.backgroundColor = backgroundColor
    }
}

public struct SplashView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = SplashViewController

    public let config: SplashViewConfig

    public init(config: SplashViewConfig) {
        self.config = config
    }

    public func makeUIViewController(context: Context) -> SplashViewController {
        let vc = SplashViewController()
        vc.animatedView.image = config.image ?? UIImage(named: "Logo", in: .module, with: nil)
        vc.animatedView.imageColor = UIColor(config.imageTintColor ?? .primary)
        vc.animatedView.tintColor = UIColor(config.radialTintColor ?? .primary)
        if let backgroundColor = config.backgroundColor {
            vc.backgroundColor = UIColor(backgroundColor)
        }
        return vc
    }

    public func updateUIViewController(_ uiViewController: SplashViewController, context: Context) {
        // NO-OP
    }
}
