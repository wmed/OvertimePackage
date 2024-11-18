//
//  UIKitExtensions.swift
//  
//
//  Created by Daniel Baldonado on 10/3/24.
//

import UIKit
import SafariServices
import SwiftUI

extension UIView {
    public func centerInSuperview() {
        guard let superview else { return }

        let horizontalConstraint = centerXAnchor.constraint(equalTo: superview.centerXAnchor)
        let verticalConstraint = centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint])
    }
    
    public func pinEdgesToSuperviewEdges() {
        guard let superview else { return }

        let topConstraint = topAnchor.constraint(equalTo: superview.topAnchor)
        let bottomConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        let leadingConstraint = leadingAnchor.constraint(equalTo: superview.leadingAnchor)
        let trailingConstraint = trailingAnchor.constraint(equalTo: superview.trailingAnchor)

        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
    }

    public func constrainDimensions(width: CGFloat, height: CGFloat) {
        let widthConstraint = widthAnchor.constraint(equalToConstant: width)
        let heightConstraint = heightAnchor.constraint(equalToConstant: height)

        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
    }
}

public struct SFSafariView: UIViewControllerRepresentable {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariView>) {
        // No need to do anything here
    }
}

struct SafariViewControllerViewModifier: ViewModifier {
    @State private var urlToOpen: URL?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                /// Catch any URLs that are about to be opened in an external browser.
                /// Instead, handle them here and store the URL to reopen in our sheet.
                urlToOpen = url
                return .handled
            })
            .sheet(isPresented: $urlToOpen.mappedToBool(), onDismiss: {
                urlToOpen = nil
            }, content: {
                SFSafariView(url: urlToOpen!)
            })
    }
}

extension Binding where Value == Bool {
    public init(binding: Binding<(some Any)?>) {
        self.init(
            get: {
                binding.wrappedValue != nil
            },
            set: { newValue in
                guard newValue == false else { return }

                // We only handle `false` booleans to set our optional to `nil`
                // as we can't handle `true` for restoring the previous value.
                binding.wrappedValue = nil
            }
        )
    }

    public init(binding: Binding<any Collection>) {
        self.init(
            get: {
                !binding.wrappedValue.isEmpty
            },
            set: { newValue in
                guard newValue == false else { return }

                // We only handle `false` booleans to set our optional to `nil`
                // as we can't handle `true` for restoring the previous value.
                binding.wrappedValue = []
            }
        )
    }
}

extension Binding where Value == any Collection {
    /// Maps an optional binding to a `Binding<Bool>`.
    /// This can be used to, for example, use an `Error?` object to decide whether or not to show an
    /// alert, without needing to rely on a separately handled `Binding<Bool>`.
    public func mappedToIsNotEmpty() -> Binding<Bool> {
        Binding<Bool>(binding: self)
    }
}

extension Binding {
    /// Maps an optional binding to a `Binding<Bool>`.
    /// This can be used to, for example, use an `Error?` object to decide whether or not to show an
    /// alert, without needing to rely on a separately handled `Binding<Bool>`.
    public func mappedToBool<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(binding: self)
    }
}

extension View {
    /// Monitor the `openURL` environment variable and handle them in-app instead of via
    /// the external web browser.
    /// Uses the `SafariViewWrapper` which will present the URL in a `SFSafariViewController`.
    public func handleOpenURLInApp() -> some View {
        modifier(SafariViewControllerViewModifier())
    }
}
