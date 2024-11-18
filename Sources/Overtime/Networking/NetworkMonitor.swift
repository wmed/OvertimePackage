//
//  NetworkManager.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import NetworkExtension

public extension NSNotification.Name {
    static let wifiConnectionDidChange = NSNotification.Name("WifiConnectionDidChange")
    static let networkConnectionDidChange = NSNotification.Name("NetworkConnectionDidChange")
}

final public class NetworkMonitor {
    private let networkMonitor = NWPathMonitor()

    @Published public private(set) var isNetworkConnected: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .networkConnectionDidChange, object: self)
        }
    }

    @Published public private(set) var isWifiConnected: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .wifiConnectionDidChange, object: self)
        }
    }


    public init() {
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isNetworkConnected = path.status == .satisfied
                self.isWifiConnected = path.usesInterfaceType(.wifi)
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "wifiMonitor"))
    }
}
