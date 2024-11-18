//
//  ApplicationConfiguration.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import UIKit

internal struct ApplicationConfiguration: Decodable {
    var id: String
    var app_id: String
    var app_name: String?
    var minimum_build_number: Int
    var suggested_build_number: Int?
    var configuration: [String: String]?
}

private struct AppConfigurationResponse: Decodable {
    var app_configuration: ApplicationConfiguration
}

private struct AppConfigurationFetchResponse: FetchResponse {
    typealias Object = ApplicationConfiguration
    static var model: OvertimeObject.Type? = nil
    func objects() -> [Object] {
        [app_configuration]
    }
    var app_configuration: Object
}

public extension String {
    internal static let configurationUpdatePromptKey = "ConfigurationUpdatePromptKey"
    static let debugConfigurationUpdatePromptKey = "debugConfigurationUpdatePromptKey"
}

extension SessionManager {
    internal func fetchConfiguration() async -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            applicationConfiguration = nil
            return false
        }

        do {
            let response = try await fetch(options:
                    .init(
                        path:"api/app_configurations/v1/app_id/\(bundleId)",
                        decodable: AppConfigurationFetchResponse.self
                    )
            )
            applicationConfiguration = response.app_configuration
            return true
        } catch let error {
            applicationConfiguration = nil
            logManager.log(error: error, description: "Failed to fetch app configuration")
            return false
        }
    }
}
