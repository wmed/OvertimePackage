//
//  OvertimeApplication.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import SafariServices
import UIKit

public struct OvertimeViewControllerConfiguration {
    public var tintColor = UIColor.brandSecondary
    public var backgroundColor = UIColor.brandPrimary
    public var backgroundImage = UIImage()
    public var titleFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    public var font = UIFont.systemFont(ofSize: 14, weight: .regular)
    public var titleIsUppercase = false
    public var statusBarStyle = UIStatusBarStyle.default
}

//public enum OvertimeApplicationStage {
//    case splash(OvertimeViewControllerConfiguration, SplashViewControllerConfiguration?)
//    case authentication(OvertimeViewControllerConfiguration)
//    case termsOfService(OvertimeViewControllerConfiguration, TermsOfServiceViewControllerConfiguration)
//    case permissions(OvertimeViewControllerConfiguration)
//    case profile(OvertimeViewControllerConfiguration)
//    case closure(() -> UIViewController?)
//    case viewController(ViewController.Type)
//    case storyboard(UIStoryboard)
//}

//public class OvertimeApplication {
//    public static let shared = OvertimeApplication()
//
//    private var applicationQueueIndex = 0
//    public var applicationQueue: [OvertimeApplicationStage] = []
//    public var permissions: [Permission] = []
//    private var isCheckingPermissions = false
//    private var isApplicationReady = false
//
//    public private(set) var navigationController: NavigationController
//
//    private init() {
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//
//        navigationController = NavigationController()
//        navigationController.isNavigationBarHidden = true
//
//        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
//    }
//
//    @objc func applicationDidForeground() {
//        checkForUpdate()
//        checkForModeration()
//    }
//
//    func checkForUpdate() {
//        switch ConfigurationManager.shared.requiresUpdate {
//        case .required:
//            promptUpdate(required: true)
//            return
//        case .suggested:
//            let lastPromptTime = UserDefaults.standard.double(forKey: .configurationUpdatePromptKey)
//            let debugPomptTime = UserDefaults.standard.bool(forKey: .debugConfigurationUpdatePromptKey)
//            let lastPromptDate = Date(timeIntervalSince1970: lastPromptTime)
//            let nextPromptDate = lastPromptDate.addingTimeInterval(6 * 60 * 60)
//            let currentDate = Date()
//            if currentDate > nextPromptDate || debugPomptTime {
//                UserDefaults.standard.set(currentDate.timeIntervalSince1970, forKey: .configurationUpdatePromptKey)
//                promptUpdate(required: false)
//            }
//        case .upToDate:
//            break
//        }
//    }

//    public func checkForModeration() -> Bool {
//        if navigationController.currentViewController?.isKind(of: UserModerationViewController.self) ?? false {
//            return false
//        }
//        if let user = SessionManager.shared.currentUser,
//              user.is_banned ||
//                user.is_username_change_required ||
//                user.is_name_change_required ||
//                user.is_image_change_required ||
//                user.is_bio_change_required ||
//                user.is_comment_acknowledge_required
//        {
//            let viewController = UserModerationViewController()
//            viewController.modalPresentationStyle = .overFullScreen
//            viewController.modalPresentationCapturesStatusBarAppearance = true
//            if user.is_banned {
//                viewController.state = .banned
//            } else if user.is_username_change_required {
//                viewController.state = .changeUsername
//            } else if user.is_name_change_required {
//                viewController.state = .changeName
//            } else if user.is_image_change_required {
//                viewController.state = .changeImage
//            } else if user.is_bio_change_required {
//                viewController.state = .changeBio
//            }
//            if user.is_comment_acknowledge_required {
//                viewController.state = .comments
//                Task { [weak self] in
//                 _ = try? await SessionManager.shared.fetchModeratedComments()
//                        await self?.navigationController.currentViewController?.present(viewController, animated: true, completion: nil)
//                }
//                return true
//            } else {
//                navigationController.currentViewController?.present(viewController, animated: true, completion: nil)
//                return true
//            }
//        }
//
//        return false
//    }

//    var isLoggedIn = false
//    var hasRequestedPermissions = false
