//
//  ApplicationLoader.swift
//
//
//  Created by Daniel Baldonado on 10/3/24.
//

import SwiftUI

public struct ApplicationConfig {
    public let splashConfig: SplashViewConfig
    public let loadingAction: () async -> Void

    public init(splashConfig: SplashViewConfig, loadingAction: @escaping () async -> Void) {
        self.splashConfig = splashConfig
        self.loadingAction = loadingAction
    }
}

extension URL {
    fileprivate static let appStoreUrl = URL(string: Bundle.main.object(forInfoDictionaryKey: "AppStoreUrl") as? String ?? "itms-apps://apps.apple.com")!
}

public struct ApplicationLoader<Content: View>: View {
    public let appConfig: ApplicationConfig
    @ViewBuilder public let content: Content
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.scenePhase) var scenePhase

    @State private var loaded: Bool = false
    @State private var showsRequiredUpdate: Bool = false
    @State private var showsSuggestedUpdate: Bool = false
    @State private var showModerationAcknowledgement: Bool = false

    public init(appConfig: ApplicationConfig, @ViewBuilder content: @escaping () -> Content) {
        self.appConfig = appConfig
        self.content = content()
    }

    func promptForUpdateIfNeeded() {
        switch sessionManager.appUpdateStatus {
        case .required:
            showsRequiredUpdate = true
        case .suggested:
            let lastPromptTime = UserDefaults.standard.double(forKey: .configurationUpdatePromptKey)
            let debugPomptTime = UserDefaults.standard.bool(forKey: .debugConfigurationUpdatePromptKey)
            let lastPromptDate = Date(timeIntervalSince1970: lastPromptTime)
            let nextPromptDate = lastPromptDate.addingTimeInterval(6 * 60 * 60)
            let currentDate = Date()
            if currentDate > nextPromptDate || debugPomptTime {
                UserDefaults.standard.set(currentDate.timeIntervalSince1970, forKey: .configurationUpdatePromptKey)
                showsSuggestedUpdate = true
            }
        case .upToDate:
            break
        }
    }

    func checkForModeration() -> Bool {
        if let user = sessionManager.currentUser,
              user.is_banned ||
                user.is_username_change_required ||
                user.is_name_change_required ||
                user.is_image_change_required ||
                user.is_bio_change_required ||
                user.is_comment_acknowledge_required
        {
            showModerationAcknowledgement = true
        }

        return false
    }

    public var body: some View {
        if loaded {
            content
                .alert("New Updates Available", isPresented: $showsSuggestedUpdate, actions: {
                    Button("Update") {
                        UIApplication.shared.open(.appStoreUrl, options: [:], completionHandler: nil)
                    }
                    Button("Dismiss", role: .cancel) { }
                }, message: {
                    Text("An app update is available in the App Store.")
                })
                .alert("New Update Required", isPresented: $showsRequiredUpdate, actions: {
                    Button("Update") {
                        UIApplication.shared.open(.appStoreUrl, options: [:], completionHandler: nil)
                    }
                }, message: {
                    Text("Your app is out of date. You must download the latest version to proceed.")
                })
                .onAppear(perform: {
                    promptForUpdateIfNeeded()
                })
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        Task {
                            _ = await sessionManager.fetchConfiguration()
                            await MainActor.run {
                                self.promptForUpdateIfNeeded()
                            }
                            await appConfig.loadingAction()
                        }
                    case .inactive, .background:
                        break
                    }
                }
        } else {
            SplashView(config: appConfig.splashConfig)
                .onAppear(perform: {
                    Task {
                        _ = await sessionManager.fetchConfiguration()
                        do {
                            let isLoggedIn = try await sessionManager.isLoggedIn()
                        } catch {
                            sessionManager.logManager.log(error: error, description: "Could not check log in")
                        }
                        await appConfig.loadingAction()
                        await MainActor.run {
                            self.loaded = true
                        }
                    }
                })
                .edgesIgnoringSafeArea(.all)
        }
    }
}
