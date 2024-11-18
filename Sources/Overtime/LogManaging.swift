//
//  LogManaging.swift
//
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation

public enum LogCategory {
    case info
    case timing
    case warning
    case error
    case performance
    case event

    var icon: String {
        switch self {
        case .info:
            return "❓"
        case .timing:
            return "⌛️"
        case .warning:
            return "⚠️"
        case .error:
            return "❗️"
        case .performance:
            return "📈"
        case .event:
            return "💬"
        }
    }
}

public protocol LogManaging {
    func log(message: String)
    func log(message: String, category: LogCategory)
    func log(trackingEvent: String)
    func log(trackingEvent: String, properties: [String: Any])
    func log(error: Error?, description: String)
    func log(error: Error?, description: String, properties: [String: Any])
}

public protocol AnalyticsManaging {
    func trackEvent(_ event: String, properties: [String: Any])
    func trackError(_ error: String, properties: [String: Any])
    func setUserIdentity(user: User)
}

public class DefaultLogManager: LogManaging {
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd H:m:ss.SSSS"
        return formatter
    }()

    private let analyticsManager: AnalyticsManaging

    public init(analyticsManager: AnalyticsManaging = EmptyAnalyticsManager()) {
        self.analyticsManager = analyticsManager
    }

    public func log(message: String) {
        log(message: message, category: .info)
    }

    public func log(trackingEvent: String) {
        log(trackingEvent: trackingEvent, properties: [:])
    }

    public func log(error: Error?, description: String) {
        log(error: error, description: description, properties: [:])
    }

    public func log(message: String, category: LogCategory) {
    #if DEBUG || targetEnvironment(simulator)
        let fullMessage = "\(category.icon) \(dateFormatter.string(from: Date())) \(message)"
        print(fullMessage)
    #endif
    }

    public func log(trackingEvent: String, properties: [String: Any]) {
        let message = "\(trackingEvent) \(properties)"
        log(message: message, category: .event)
        analyticsManager.trackEvent(trackingEvent, properties: properties)
    }

    public func log(error: Error?, description: String, properties: [String: Any] = [:]) {
        let message = "Error: \(description) \(error?.localizedDescription ?? "")"
        log(message: message, category: .error)
        var underlyingErrors: String?
        if let nsError = error as? NSError {
            underlyingErrors = nsError.underlyingErrors.reduce("") { partialResult, error in
                let nsError = error as NSError
                return partialResult + nsError.localizedDescription + "\n"
            }
        }
        var params = properties
        params["underying_errors"] = underlyingErrors
        params["error"] = error?.localizedDescription ?? "Untracked Error"
        analyticsManager.trackError(description, properties: params)
    }
}

public class EmptyAnalyticsManager: AnalyticsManaging {
    public func setUserIdentity(user: User) {
        // NO-OP
    }
    
    public func trackEvent(_ event: String, properties: [String : Any]) {
        // NO-OP
    }

    public func trackError(_ error: String, properties: [String : Any]) {
        // NO-OP
    }

    public init() { }
}
