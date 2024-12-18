//
//  SessionManager.swift
//
//  Created by Daniel Baldonado on 8/22/24.
//

import Alamofire
import CryptoSwift
import NetworkExtension
import RealmSwift
import UIKit

public typealias Parameters = [String: Any]

public struct Response {
    public let statusCode: Int?
    public let data: Data?
    public let metrics: ResponseMetrics
}

public struct ResponseMetrics {
    public let taskInterval: TimeInterval
}

public enum RequestEncoding {
    case json
    case form
}

public enum RequestError: Error {
    case invalidUrl(urlString: String)
    case badStatus(errorCode: Int)
    case decodeError(error: Error)
    case serializationError(error: Error)
    case stringEncodingError(encoding: String)
    case notFound
    case writeError
    case unexpected
    case emptyResponse
    case noResponse
    case unknown(error: Error?)
}

extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badStatus(let statusCode):
            return "Bad Status: \(statusCode)"
        case .decodeError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serializationError(let error):
            return "Serialization error: \(error.localizedDescription)"
        case .stringEncodingError(let encoding):
            return "Encoding error: \(encoding)"
        case .notFound:
            return "Request not found"
        case .unexpected:
            return "Unexepected response from request"
        case .writeError:
            return "Write error on request"
        case .unknown:
            return "Unknown request error"
        case .emptyResponse:
            return "Empty response"
        case .noResponse:
            return "No request was made"
        case .invalidUrl(urlString: let urlString):
            return "Invalid URL for request: \(urlString)"
        }
    }
}

public struct RequestErrorResponse: Decodable, Equatable {
    let statusCode: Int
    let error: String
    let message: String?
}

public extension NSNotification.Name {
    static let overtimeCurrentUserDidChange = NSNotification.Name("OvertimeCurrentUserDidChange")
    static let overtimeAuthenticationDidChange = NSNotification.Name("OvertimeAuthenticationDidChange")
}

private extension TimeInterval {
    static let defaultNetworkTimeout: TimeInterval = 10
}

private extension String {
    static let authTokenKey = "OvertimeAuthToken"
    static let deviceIdKey = "OvertimeDeviceId"
    static let deviceUserIdKey = "OvertimeDeviceUserId"
    static let currentUserIdKey = "OvertimeCurrentUserId"
    static let appUpdateStatusKey = "appUpdateStatus"
}

public class SessionManager: ObservableObject {
    // MARK: Init
    private let networkMonitor: NetworkMonitor
    internal let logManager: LogManaging
    internal let analyticsManager: AnalyticsManaging

    public init(environment: Environment = .production,
                allowOfflineMode: Bool = false,
                allowAnonymousLogin: Bool = true,
                networkMonitor: NetworkMonitor = NetworkMonitor(),
                analyticsManager: AnalyticsManaging = EmptyAnalyticsManager(),
                logManager: LogManaging? = nil
    ) {
        self.environment = environment
        self.allowOfflineMode = allowOfflineMode
        self.allowAnonymousLogin = allowAnonymousLogin
        self.networkMonitor = networkMonitor
        self.analyticsManager = analyticsManager
        self.logManager = logManager ?? DefaultLogManager(analyticsManager: analyticsManager)

        pingPresence()
    }

    // MARK: Session Settings
    public enum Environment {
        case production
        case staging
        case development

        internal var hostURLString: String {
            switch self {
            case .production, .development:
                return "https://api.itsovertime.com/"
            case .staging:
                return "https://stg-api.itsovertime.com/"
            }
        }
    }

    private var environment: Environment = .production
    private var baseURL: String { return environment.hostURLString }

    public func setEnvironment(_ environment: Environment) {
        self.environment = environment
    }

    internal let allowAnonymousLogin: Bool
    // Offline mode only applicable when allowAnonymousLogin set to false
    internal let allowOfflineMode: Bool

    // MARK: Configuration
    internal var applicationConfiguration: ApplicationConfiguration? {
        didSet {
            refreshAppUpdateStatus()
        }
    }
    public var configuration: [String:Any]? {
        return applicationConfiguration?.configuration
    }

    public enum ApplicationUpdateStatus: Int {
        case upToDate
        case required
        case suggested
    }

    public private(set) var appUpdateStatus: ApplicationUpdateStatus {
        get {
            let int = UserDefaults.standard.integer(forKey: .appUpdateStatusKey)
            return ApplicationUpdateStatus(rawValue: int) ?? .upToDate
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: .appUpdateStatusKey)
        }
    }

    func refreshAppUpdateStatus() {
        guard let applicationConfiguration else {
            appUpdateStatus = .upToDate
            return
        }

        let buildNumber = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
        logManager.log(message: "Current build \(buildNumber). Required build \(applicationConfiguration.minimum_build_number)")
        if buildNumber < applicationConfiguration.minimum_build_number {
            appUpdateStatus = .required
        } else if let suggested = applicationConfiguration.suggested_build_number, buildNumber < suggested {
            appUpdateStatus = .suggested
        } else {
            appUpdateStatus = .upToDate
        }
    }

    // MARK: Auth
    private(set) public var sessionToken: String? = UserDefaults.standard.string(forKey: .authTokenKey)

    public private(set) var isAuthenticating = false
    public private(set) var isAuthenticated = false {
        didSet {
            NotificationCenter.default.post(name: .overtimeAuthenticationDidChange, object: self)
        }
    }

    public private(set) var currentUserId: String? {
        didSet {
            if oldValue != currentUserId {
                NotificationCenter.default.post(name: .overtimeCurrentUserDidChange, object: nil)
                updateSessionIdentity()
            }
        }
    }

    public var currentUser: User? {
        get {
            let userId = currentUserId ?? (allowOfflineMode ? UserDefaults.standard.string(forKey: .currentUserIdKey) : nil)
            return User.findOne(userId)
        }
    }

    public private(set) var isAdmin: Bool = false
    public private(set) var isTester: Bool = false
    public var isDeviceUser: Bool {
        get {
            guard let currentUser else { return true }
            return !currentUser.phone_verified
        }
    }

    public func deleteAccount(appContext: String) async -> Bool {
        guard let userId = currentUserId else { return false }

        do {
            _ =  try await request("api/writer/\(appContext)/v1/accounts", method: .delete, parameters: nil, authenticated: true)
        } catch let error {
            logManager.log(error: error, description: "Failed to delete account")
            return false
        }
        return true
    }

    // MARK: Session Identity
    public func updateSessionIdentity() {
        guard let currentUser else {
            logManager.log(message: "No user logged in")
            return
        }
        logManager.log(message: "User set to \(currentUser.username ?? "No username")")
        analyticsManager.setUserIdentity(user: currentUser)
    }

    // MARK: Networking
    private var requestHeaders: HTTPHeaders {
        guard let sessionToken else { return HTTPHeaders() }
        return HTTPHeaders([
            "Authorization": "Bearer \(sessionToken)"
        ])
    }

    public enum RequestPriority {
        case background
        case `default`
        case immediate
    }

    public func download(path: String, host: String, authenticated: Bool = true) async throws -> (url: URL, response: URLResponse) {
        let headers = authenticated ? requestHeaders : [:]

        let urlString = "\(host)/\(path)"
        guard let url = URL(string: urlString),
              let urlRequest = try? URLRequest(url: url, method: .get, headers: headers)
        else {
            throw RequestError.invalidUrl(urlString: urlString)
        }

        logManager.log(message: "Downloading from \(path)", category: .info)
        return try await URLSession.shared.download(for: urlRequest, delegate: nil)
    }

    public func upload(_ path: String,
                       data: Data,
                       validStatusCodes: Range<Int> = 200..<300,
                       authenticated: Bool = false,
                       timeout: TimeInterval? = nil) async throws -> Response {
        let timeout = timeout ?? .defaultNetworkTimeout
        guard let url = URL(string: baseURL + path) else { throw RequestError.invalidUrl(urlString: baseURL + path) }
        let headers = authenticated ? requestHeaders : [:]
        var request = try URLRequest(url: url, method: .post, headers: headers)
        request.timeoutInterval = timeout
        request.httpShouldHandleCookies = false

        request.addValue("application/octet-stream", forHTTPHeaderField: "content-type")
        request.addValue(data.md5().toHexString(), forHTTPHeaderField: "Content-MD5")

        logManager.log(message: "Uploading to \(path)", category: .timing)

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let afRequest = try await AF.upload(data, with: request)
                .validate(statusCode: validStatusCodes)
                .serializingResponse(using: OvertimeResponseSerializer())
                .value

            let response = afRequest.reponse
            let data = afRequest.data

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            logManager.log(message: "Upload to \(path) completed in \(elapsed)", category: .timing)

            let requestResponse = Response(
                statusCode: response.statusCode,
                data: data,
                metrics: ResponseMetrics(taskInterval: elapsed)
            )
            return requestResponse
        } catch AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)) where statusCode == 404 {
            throw RequestError.notFound
        } catch AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)) {
            throw RequestError.badStatus(errorCode: statusCode)
        } catch AFError.responseSerializationFailed(reason: let reason) {
            switch reason {
            case .decodingFailed(let error):
                throw RequestError.decodeError(error: error)
            case .stringSerializationFailed(let encoding):
                throw RequestError.stringEncodingError(encoding: encoding.description)
            case .jsonSerializationFailed(let error):
                throw RequestError.serializationError(error: error)
            case .customSerializationFailed(let error):
                throw RequestError.serializationError(error: error)
            case .inputDataNilOrZeroLength, .invalidEmptyResponse, .inputFileNil:
                throw RequestError.emptyResponse
            default:
                throw RequestError.unexpected
            }
        } catch let error {
            throw RequestError.unknown(error: error)
        }
    }

    public func request(_ path: String,
                           method: HTTPMethod = .get,
                           parameters: Parameters? = nil,
                           validStatusCodes: Range<Int> = 200..<300,
                           encoding: RequestEncoding = .json,
                           authenticated: Bool = false,
                           decodeBody: Bool = false,
                           timeout: TimeInterval? = nil
    ) async throws -> Response {
        let timeout = timeout ?? .defaultNetworkTimeout
        let encoding: ParameterEncoding = encoding == .json && method != .get ? JSONEncoding.default : URLEncoding(boolEncoding: .literal)

        let headers = authenticated ? requestHeaders : [:]

        if path.starts(with: "/") {
            logManager.log(message: "Extra leading / in path", category: .warning)
        }

        logManager.log(message: "Requesting \(method.rawValue) \(path)", category: .timing)

        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let response = try await AF.request(baseURL + path,
                                               method: method,
                                               parameters: parameters,
                                               encoding: encoding,
                                               headers: headers) { request in
                    request.timeoutInterval = timeout
                    request.httpShouldHandleCookies = false
                }
                .validate(statusCode: validStatusCodes)
                .serializingResponse(using: OvertimeResponseSerializer())
                .value

            let urlResponse = response.reponse
            let data = response.data

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            logManager.log(message: "Request for \(method.rawValue) \(path) completed in \(elapsed)", category: .timing)
            let json = decodeBody ? try? JSONSerialization.jsonObject(with: data, options: []) : [:]

            let requestResponse = Response(
                statusCode: urlResponse.statusCode,
                data: data,
                metrics: ResponseMetrics(taskInterval: elapsed)
            )
            return requestResponse
        } catch AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)) where statusCode == 404 {
            throw RequestError.notFound
        } catch AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)) {
            throw RequestError.badStatus(errorCode: statusCode)
        } catch AFError.responseSerializationFailed(reason: let reason) {
            switch reason {
            case .decodingFailed(let error):
                throw RequestError.decodeError(error: error)
            case .stringSerializationFailed(let encoding):
                throw RequestError.stringEncodingError(encoding: encoding.description)
            case .jsonSerializationFailed(let error):
                throw RequestError.serializationError(error: error)
            case .customSerializationFailed(let error):
                throw RequestError.serializationError(error: error)
            case .inputDataNilOrZeroLength, .invalidEmptyResponse, .inputFileNil:
                throw RequestError.emptyResponse
            default:
                throw RequestError.unexpected
            }
        } catch let error {
            logManager.log(error: error, description: "Unknown Request Error")
            throw RequestError.unknown(error: error)
        }
    }

    public func decodedRequest<T>(_ path: String,
                                  method: HTTPMethod = .get,
                                  parameters: Parameters? = nil,
                                  validStatusCodes: Range<Int> = 200..<300,
                                  encoding: RequestEncoding = .json,
                                  authenticated: Bool = false,
                                  decodeBody: Bool = false,
                                  timeout: TimeInterval? = nil
    ) async throws -> T where T: Decodable {
        let timeout = timeout ?? .defaultNetworkTimeout
        let response = try await request(path, 
                                         method: method,
                                         parameters: parameters,
                                         validStatusCodes: validStatusCodes,
                                         encoding: encoding,
                                         authenticated: authenticated,
                                         decodeBody: decodeBody,
                                         timeout: timeout)

        guard let data = response.data else {
            throw RequestError.unexpected
        }

        let decodedResponse = try await withCheckedThrowingContinuation { continuation in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let decodable = try decoder.decode(T.self, from: data)
                continuation.resume(returning: decodable)
            } catch {
                let body = String(data: data, encoding: .utf8) ?? ""
                logManager.log(error: error, description: body)
                continuation.resume(throwing: RequestError.decodeError(error: error))
            }
        }
        return decodedResponse
    }
}

//MARK: User
extension SessionManager {
    public func checkUsernameAvailability(username: String) async -> Bool {
        do {
            _ =  try await request("api/users/v1/username_available/\(username)", method: .get, parameters: nil, authenticated: true)
        } catch {
            return false
        }
        return true
    }
}

// MARK: FetchResponse
public protocol FetchResponse: Decodable {
    associatedtype Object: Decodable
    func objects() -> [Object]
    static var model: OvertimeObject.Type? { get }
    static func dateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy
}

extension FetchResponse {
    public static func dateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy { return .formatted(DateFormatter.iso8601Full) }
}

public extension SessionManager.FetchOptions where T: FetchResponse {
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return decodable.dateDecodingStrategy()
    }
}

// MARK: Fetch
public extension SessionManager {
    struct FetchOptions<T: FetchResponse> {
        public var path: String
        public var method: HTTPMethod = .get
        public var parameters: Parameters?
        public var decodable: T.Type
        public var timeout: TimeInterval

        public init(path: String,
                    method: HTTPMethod = .get,
                    parameters: Parameters? = nil,
                    decodable: T.Type,
                    timeout: TimeInterval? = nil) {
            self.path = path
            self.method = method
            self.parameters = parameters
            self.decodable = decodable
            self.timeout = timeout ?? .defaultNetworkTimeout
        }
    }

    @available(*, deprecated, renamed: "fetch")
    func fetchDecodable<T>(options: FetchOptions<T>) async throws -> T where T.Object: Decodable {
        return try await fetch(options: options)
    }

    func fetch<T>(options: FetchOptions<T>) async throws -> T where T.Object: Decodable {
        do {
            let response = try await request(
                options.path,
                method: options.method,
                parameters: options.parameters,
                authenticated: true,
                timeout: options.timeout)

            guard let data = response.data else {
                throw RequestError.unexpected
            }

            let decodedResponse = try await withCheckedThrowingContinuation { continuation in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = options.decodable.dateDecodingStrategy()

                do {
                    let decodable = try decoder.decode(options.decodable, from: data)
                    continuation.resume(returning: decodable)
                } catch {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    logManager.log(error: error, description: body)
                    continuation.resume(throwing: RequestError.decodeError(error: error))
                }
            }

            return decodedResponse
        } catch let error as RequestError {
            logManager.log(error: error, description: "Error fetching \(options.path)")
            throw error
        } catch let error {
            logManager.log(error: error, description: "Unexpected error fetching \(options.path)")
            throw RequestError.unknown(error: error)
        }
    }

    func fetchOvertimeObject<T>(
        options: FetchOptions<T>
    ) async throws -> T where T.Object: OvertimeDecodable {
        let result = try await fetch(options: options)
        if let model = options.decodable.model {
            do {
                try await Realm(actor: MainActor.shared).loggedAsyncWrite {
                    result.objects().forEach({ _ = model.from($0) })
                }
            } catch {
                logManager.log(error: error, description: "Could not write to realm")
            }
        }
        return result
    }
}

//MARK: Authentication
extension SessionManager {
    public func isLoggedIn() async throws -> Bool {
        let wasDeviceUser = isDeviceUser
        isAuthenticating = true
        let defaults = UserDefaults.standard

        // If we know network is out, default to current user and avoid authentications if offline mode enabled
        if !allowAnonymousLogin && allowOfflineMode && !networkMonitor.isNetworkConnected {
            currentUserId = UserDefaults.standard.string(forKey: .currentUserIdKey)
            isAuthenticated = false
            isAuthenticating = false
            return currentUser != nil
        }

        guard let token = sessionToken else {
            if !allowAnonymousLogin {
                isAuthenticating = false
                return false
            }
            guard try await createDeviceUser() else {
                return false
            }
            return try await isLoggedIn()
        }

        guard let success = try? await validateAuthToken(token) else {
            isAuthenticating = false
            logout()
            return false
        }
        if isDeviceUser && !allowAnonymousLogin {
            return false
        }
        if wasDeviceUser {
            //Migrate
            _ = try await migrateDeviceUser()
        }


        isAuthenticating = false
        return success
    }

    private struct TokenVerifyResponse: Codable {
        var token: String
    }

    private struct TokenRefreshResponse: Codable {
        var token: String
        var data: AuthenticationUserData
    }

    private struct AuthenticationUserData: Codable {
        var user: AuthenticationUser
    }

    private struct AuthenticationUser: Codable {
        var uuid: String
        var roles: [String]?
    }

    public func validateAuthToken(_ token:String) async throws -> Bool {
        sessionToken = token
        do {
            let response: TokenRefreshResponse = try await decodedRequest("api/auth/refresh_token", method: .get, parameters: nil, authenticated: true)

            let user = response.data.user
            let defaults = UserDefaults.standard
            defaults.set(token, forKey: .authTokenKey)
            defaults.set(user.uuid, forKey: .currentUserIdKey)
            defaults.synchronize()

            currentUserId = user.uuid

            if let roles = user.roles, roles.contains("mod") {
                isAdmin = true
            } else{
                isAdmin = false
            }
            if let roles = user.roles, roles.contains("tester") {
                isTester = true
            } else{
                isTester = false
            }

            _ = try? await [
                updatePresence(),
                refreshUser(withChildren: true)
            ]

            isAuthenticated = true
            return true
        } catch let error as RequestError {
            isAuthenticated = false
            logManager.log(error: error, description: "Failed to verify token")
            if case let .badStatus(statusCode) = error,
               400 ..< 500 ~= statusCode {
                //Invalid code
                return false
            } else {
                //Retry for network problems or assume true if offline mode allowed
                if allowOfflineMode { return true }
                return try await validateAuthToken(token)
            }
        } catch {
            logManager.log(error: error, description: "Could not refresh token")
            isAuthenticated = false
            //Retry for network problems or assume true if network disconnected
            if allowOfflineMode { return true }
            return try await validateAuthToken(token)
        }
    }

    public func refreshUser(withChildren: Bool = false) async throws -> Bool {
        guard let id = currentUserId else {
            return false
        }

        let wasUser = await User.findOne(id)

        _ = try await fetchOvertimeObject(options: FetchOptions(path: "api/users/v1/\(id)?nocache=true", decodable: UserFetchResponse.self))
        if wasUser == nil {
            //Notify listeners the user is actually in Realm now
            NotificationCenter.default.post(name: .overtimeCurrentUserDidChange, object: nil)
        }
        if withChildren {
            let response = try await fetch(options:
                                            FetchOptions(
                                                path: "api/users/v1/\(id)/notification_types",
                                                decodable: UserNotificationTypesFetchResponse.self
                                            )
            )

            let user = await User.findOne(id)
            try await user?.asyncWrite {
                guard let user = user?.thaw() else { return }
                user.notification_types.removeAll()
                user.notification_types.append(objectsIn: response.notification_types)
            }
        }
        return true
    }

    public enum SendVerificationResult {
        case networkFailure
        case forbidden
        case badRequest
        case success
    }

    public func sendVerificationTo(phoneNumber:String) async -> SendVerificationResult {
        let parameters: Parameters = [
            "phone" : phoneNumber.count == 10 ? "+1\(String(describing: phoneNumber))" : "+\(String(describing: phoneNumber))",
            "device_id": UserDefaults.standard.string(forKey: .deviceIdKey) ?? ""
        ]

        do {
            let response = try await request("api/auth/send_code", method: .post, parameters: parameters, authenticated: false)
            return .success
        } catch RequestError.badStatus(let statusCode) where statusCode == 400 {
            logManager.log(error: RequestError.badStatus(errorCode: statusCode), description: "Failed to send verification code")
            return .badRequest
        } catch RequestError.badStatus(let statusCode) where statusCode == 403 {
            logManager.log(error: RequestError.badStatus(errorCode: statusCode), description: "Failed to send verification code")
            return .forbidden
        } catch let error {
            logManager.log(error: error, description: "Failed to send verification code")
            return .networkFailure
        }
    }

    public func resendCodeTo(phoneNumber: String) async throws -> Bool {
        let parameters:Parameters = [
            "phone" : phoneNumber.count == 10 ? "+1\(String(describing: phoneNumber))" : "+\(String(describing: phoneNumber))"
        ]

        do {
            _ = try await request("api/auth/resend_code", method: .post, parameters: parameters, authenticated: false)
            return true
        } catch let error {
            logManager.log(error: error, description: "Failed to resend verification code")
            return false
        }
    }

    public struct VerificationError: Error {}
    public func verify(phoneNumber: String, with code: String) async throws -> String {
        let parameters:Parameters = [
            "phone" : phoneNumber.count == 10 ? "+1\(String(describing: phoneNumber))" : "+\(String(describing: phoneNumber))",
            "code" : code
        ]

        do {
            let response: TokenVerifyResponse = try await decodedRequest("api/auth/verify_code", method: .post, parameters: parameters, authenticated: false)
            return response.token
        } catch let error {
            logManager.log(error: error, description: "Failed to verify verification code")
            throw VerificationError()
        }
    }

    private func createDeviceUser() async throws -> Bool {
        let defaults = UserDefaults.standard
        let deviceId: String = {
            if let deviceId = defaults.string(forKey: .deviceIdKey) {
                return deviceId
            }
            let deviceId = UUID().uuidString
            defaults.set(deviceId, forKey: .deviceIdKey)
            defaults.synchronize()
            return deviceId
        }()

        do {
            let response: TokenVerifyResponse = try await decodedRequest("api/auth/device_id",
                                                                         method: .post,
                                                                         parameters: ["device_id": deviceId],
                                                                         authenticated: false)

            let verified = try await validateAuthToken(response.token)
            if verified, let userId = currentUserId {
                defaults.set(userId, forKey: .deviceUserIdKey)
                defaults.synchronize()
            }
            return verified
        } catch RequestError.decodeError(error: let error) {
            logManager.log(error: error, description: "Receieved unexpected response on device user fetch")
            return false
        } catch let error {
            logManager.log(error: error, description: "Failed to fetch device user")
            return try await createDeviceUser()
        }
    }

    public func migrateDeviceUser() async throws -> Bool {
        guard let currentUserId else {
            return false
        }
        guard let currentUser else {
            return false
        }
        guard allowAnonymousLogin else {
            return true
        }
        let defaults = UserDefaults.standard
        let deviceUserId = defaults.string(forKey: .deviceUserIdKey)
        guard let deviceId = defaults.string(forKey: .deviceIdKey), let deviceUserId else {
            logManager.log(error: nil, description: "No device user id to migrate")
            if deviceUserId == nil, let userId = currentUser.id {
                defaults.set(userId, forKey: .deviceUserIdKey)
                defaults.synchronize()
            }

            return false
        }
        if currentUserId == deviceUserId {
            return true
        }
        if currentUser.device_ids.contains(deviceId) {
            //Already migrated
            return true
        }
        do {
            _ = try await request("api/writer/users/v1/\(currentUserId)/transfer_from/\(deviceUserId)",
                                     method: .post,
                                     parameters: nil,
                                     authenticated: true)
            return try await refreshUser(withChildren: true)
        } catch let error {
            logManager.log(error: error, description: "Failed to migrate user")
            return false
        }
    }


    public func logout() {
        logManager.log(trackingEvent: "Logged Out")

        //Wipe user info
        self.sessionToken = nil
        UIApplication.shared.unregisterForRemoteNotifications()
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        currentUserId = nil
        isAdmin = false
        isTester = false

        Task {
            let realm = try await Realm(actor: MainActor.shared)
            try await realm.loggedAsyncWrite {
                realm.deleteAll()
            }
        }
    }
}

//MARK: Profile {
extension SessionManager {
    public func updateProfile(fields: Parameters) async -> Bool {
        guard let userId = currentUserId else { return false }
        do {
            _ = try await fetchOvertimeObject(options: FetchOptions(path: "api/writer/users/v1/\(userId)",
                                                                    method: .put,
                                                                    parameters: fields,
                                                                    decodable: UserFetchResponse.self))
            return true
        } catch {
            return false
        }
    }
}


struct UserPresenceFetchResponse: FetchResponse {
    static var model: OvertimeObject.Type?

    typealias Object = UserPresenceDecodable
    func objects() -> [Object] {
        [user_presence]
    }
    var user_presence: Object
}

struct UserPresenceDecodable: Decodable {
    var consecutive_days_started_at: Date?
}

//MARK: Presence
extension SessionManager {
    private func pingPresence() {
        Task { [weak self] in
            _ = try? await self?.updatePresence()
            try? await Task.sleep(for: .seconds(30))
            self?.pingPresence()
        }
    }


    @MainActor
    public func updatePresence() async throws -> Bool {
        //Avoid spamming presence endpoint if no network available
        guard networkMonitor.isNetworkConnected else { return false }

        //Avoid spamming presence endpoint when neither a user or token is ready
        guard let deviceToken = UserDefaults.standard.data(forKey: "deviceToken")?.base64EncodedString(),
                !deviceToken.isEmpty && sessionToken != nil else {
            return false
        }

        let bundleInformation = Bundle.main.infoDictionary
        let name = bundleInformation?["CFBundleDisplayName"] ?? "Unknown Overtime Application"
        let version = bundleInformation?["CFBundleShortVersionString"] ?? "Unknown Version"
        let build = bundleInformation?["CFBundleVersion"] ?? "Unknown Build"
        let application = "\(name) (\(version).\(build))"
        let bundleIdentifier = bundleInformation?["CFBundleIdentifier"] as? String ?? ""
        let parameters: Parameters = [
            "application_name": application,
            "device_token": deviceToken,
            "bundle_identifier": bundleIdentifier
        ]
        let response = try await fetch(options: FetchOptions(
            path: "api/writer/user_presences/v1",
            method: .post,
            parameters: parameters,
            decodable: UserPresenceFetchResponse.self)
        )
        try? await currentUser?.asyncWrite {
            currentUser?.consecutive_days_started_at = response.user_presence.consecutive_days_started_at
        }

        return true
    }
}

//MARK: Notifications
extension SessionManager {
    public func enableNotification(_ notification: String) async throws -> Bool {
        guard let userId = currentUserId else { return false }

        do {
            let response = try await fetch(options: FetchOptions(
                path: "api/writer/users/v1/\(userId)/notification_types",
                method: .post,
                parameters: ["notification_type": notification],
                decodable: UserNotificationTypesFetchResponse.self))

            try await Realm(actor: MainActor.shared).loggedAsyncWrite {
                currentUser?.notification_types.removeAll()
                currentUser?.notification_types.append(objectsIn: response.notification_types)
            }
            return true
        } catch let error {
            logManager.log(error: error, description: "Failed to enable notification")
            return false
        }
    }

    public func disableNotification(_ notification: String) async throws -> Bool {
        guard let userId = currentUserId else { return false }

        do {
            let response = try await fetch(options: FetchOptions(
                path: "api/writer/users/v1/\(userId)/notification_types/\(notification)",
                method: .delete,
                decodable: UserNotificationTypesFetchResponse.self)
            )
            try await Realm(actor: MainActor.shared).loggedAsyncWrite {
                currentUser?.notification_types.removeAll()
                currentUser?.notification_types.append(objectsIn: response.notification_types)
            }
            return true
        } catch let error {
            logManager.log(error: error, description: "Failed to disbale notification")
            return false
        }
    }

}
