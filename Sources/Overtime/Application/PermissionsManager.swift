//
//  PermissionsManager.swift
//  
//
//  Created by Daniel Baldonado on 11/14/24.
//

import Foundation
import AVFoundation
import Photos
import UserNotifications
import UIKit

public enum Permission: String {
    case camera = "Camera"
    case microphone = "Microphone"
    case photos = "Photos"
    case location = "Location"
    case notifications = "Notifications"
}

public class PermissionsManager {
    public static let shared = PermissionsManager()

    var locationManager: CLLocationManager?
    var locationManagerDelegate: LocationManagerDelegate?

    public enum PermissionAccess {
        case granted
        case undetermined
        case denied
    }

    public func hasPermission(_ permission: Permission, completion: @escaping (PermissionAccess) -> Void) {
        switch permission {
        case .camera:
            #if os(iOS)
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                completion(.granted)
            } else if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                completion(.undetermined)
            } else {
                completion(.denied)
            }
            #endif
        case .microphone:
            #if os(iOS)
            if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
                completion(.granted)
            } else if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                completion(.undetermined)
            } else {
                completion(.denied)
            }
            #endif
        case .photos:
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                completion(.granted)
            } else if PHPhotoLibrary.authorizationStatus() == .notDetermined {
                completion(.undetermined)
            } else {
                completion(.denied)
            }
        case .location:
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                completion(.granted)
            } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
                completion(.undetermined)
            } else {
                completion(.denied)
            }
        case .notifications:
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                if settings.authorizationStatus == .authorized && settings.badgeSetting == .enabled {
                    completion(.granted)
                } else if settings.authorizationStatus == UNAuthorizationStatus.notDetermined || settings.authorizationStatus == UNAuthorizationStatus.provisional {
                    completion(.undetermined)
                } else {
                    completion(.denied)
                }
            })
        }
    }

    public func hasPermission(_ permission: Permission) async -> PermissionAccess {
        return await withCheckedContinuation { [weak self] continuation in
            self?.hasPermission(permission) { access in
                continuation.resume(returning: access)
            }
        }
    }

    func hasGrantedPermissions(_ permissions:[Permission], completion: @escaping (Bool) -> Void) {
        if permissions.count == 0 {
            completion(true)
        }

        var permissionsChecked: [Bool] = permissions.map { (_) -> Bool in
            return false
        }
        var hasPermissions: [Bool] = permissions.map { (_) -> Bool in
            return false
        }
        for (index, permission) in permissions.enumerated() {
            hasPermission(permission, completion: { access in
                permissionsChecked[index]  = true
                hasPermissions[index]  = access == .granted
                let checkedAll = permissionsChecked.reduce(true, { (checkedAll, checked) -> Bool in
                    return checkedAll && checked
                })
                if checkedAll {
                    let hasAll = hasPermissions.reduce(true, { (hasAll, has) -> Bool in
                        return hasAll && has
                    })
                    completion(hasAll)
                }
            })
        }
    }

    func hasRequestedPermissions(_ permissions:[Permission], completion: @escaping (Bool) -> Void) {
        if permissions.count == 0 {
            completion(true)
        }

        var permissionsChecked: [Bool] = permissions.map { (_) -> Bool in
            return false
        }
        var permissionsRequested: [Bool] = permissions.map { (_) -> Bool in
            return false
        }
        for (index, permission) in permissions.enumerated() {
            hasPermission(permission, completion: { access in
                permissionsChecked[index]  = true
                permissionsRequested[index] = access != .undetermined
                let checkedAll = permissionsChecked.reduce(true, { (checkedAll, checked) -> Bool in
                    return checkedAll && checked
                })
                if checkedAll {
                    let requestedAll = permissionsRequested.reduce(true, { (requestedAll, requested) -> Bool in
                        return requestedAll && requested
                    })
                    completion(requestedAll)
                }
            })
        }
    }


    public func requestPermission(_ permission: Permission, completion: @escaping (Bool) -> Void) {
        switch permission {
        case .camera:
            #if os(iOS)
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
                completion(granted)
            })
            #endif
        case .microphone:
            #if os(iOS)
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (granted) in
                completion(granted)
            })
            #endif
        case .photos:
            PHPhotoLibrary.requestAuthorization({ (status) in
                completion(status == .authorized)
            })
        case .location:
            let manager = CLLocationManager()
            let delegate = LocationManagerDelegate(handler: { (granted) in
                self.locationManager = nil
                self.locationManagerDelegate = nil
                completion(granted)
            })
            manager.delegate = delegate
            //Retain reference until auth complete
            locationManager = manager
            locationManagerDelegate = delegate

            manager.requestWhenInUseAuthorization()
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert], completionHandler: { (granted, error) in
                if let error = error {
                    completion(false)
                    return
                }
                DispatchQueue.main.async {
                    #if os(iOS)
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                }
                completion(granted)
            })
        }
    }

    public func requestPermission(_ permission: Permission) async -> PermissionAccess {
        return await withCheckedContinuation { [weak self] continuation in
            self?.requestPermission(permission) { success in
                continuation.resume(returning: success ? .granted : .denied)
            }
        }
    }
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    var completionHandler: ((Bool) -> Void)

    init(handler: @escaping (Bool) -> Void) {
        completionHandler = handler
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
}

