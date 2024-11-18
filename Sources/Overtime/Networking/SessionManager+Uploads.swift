//
//  SessionManager+Uploads.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

public struct AWSData: Codable {
    public let AccessKeyId: String
    public let SecretAccessKey: String
    public let SessionToken: String
    public let Expiration: String?
    public let S3Bucket: String
    public let S3Key: String
}

private struct TokenFetchResponse: FetchResponse {
    static var model: OvertimeObject.Type?

    typealias Object = AWSData
    func objects() -> [AWSData] {
        [AWSData(
            AccessKeyId: AccessKeyId,
            SecretAccessKey: SecretAccessKey,
            SessionToken: SessionToken,
            Expiration: Expiration,
            S3Bucket: S3Bucket,
            S3Key: S3Key
        )]
    }
    var AccessKeyId: String
    var SecretAccessKey: String
    var SessionToken: String
    var Expiration: String?
    var S3Bucket: String
    var S3Key: String
}


extension SessionManager {
    public enum UploadType: String {
        case video
        case factualQuestionPool = "factual_question_pool"

        func fileExtension() -> String {
            switch self {
            case .video:
                fallthrough
            case .factualQuestionPool:
                return "mov"
            }
        }
    }

    public func requestUploadToken(uploadType: UploadType, fileExtension: String? = nil) async throws -> AWSData? {
        let response = try await fetch(options: SessionManager.FetchOptions(
            path: "api/uploads/v1/token/\(uploadType.rawValue)",
            method: .post,
            parameters: ["filename": "upload.\(fileExtension ?? uploadType.fileExtension())"],
            decodable: TokenFetchResponse.self
        ))

        return response.objects().first
    }
}
