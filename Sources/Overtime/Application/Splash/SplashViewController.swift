//
//  SplashViewController.swift
//  
//
//  Created by Daniel Baldonado on 9/24/24.
//

import UIKit

public class SplashViewController: UIViewController {
    override public var prefersStatusBarHidden: Bool {
        true
    }

    var backgroundColor: UIColor?

    var onAnimationCompleted: () -> Bool = { return false } {
        didSet {
            animatedView.onAnimationCompleted = onAnimationCompleted
        }
    }

    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(white: 1.0, alpha: 0.7)
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?"))"
        return label
    }()

    var animatedView = AnimatedLogoView() {
        didSet {
            oldValue.removeFromSuperview()

            view.addSubview(animatedView)
            animatedView.translatesAutoresizingMaskIntoConstraints = false

            animatedView.centerInSuperview()
        }
    }

    #if os(iOS)
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    #endif

    override open func viewDidLoad() {
        super.viewDidLoad()

        addSubviews()
        addLayoutConstraints()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.backgroundColor = backgroundColor
        versionLabel.textColor = animatedView.imageColor
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animatedView.startAnimating()
    }

    func addSubviews() {
        view.addSubview(versionLabel)
        view.addSubview(animatedView)
    }

    func addLayoutConstraints() {
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive = true

        animatedView.translatesAutoresizingMaskIntoConstraints = false
        animatedView.centerInSuperview()
    }
}
