//
//  User.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation
import RealmSwift

public struct UsersFetchResponse: FetchResponse {
    public typealias Object = UserResponse
    public func objects() -> [Object] {
        users
    }
    public static var model: OvertimeObject.Type? = User.self

    public var users: [Object]
}

public struct UserFetchResponse: FetchResponse {
    public typealias Object = UserResponse
    public static var model: OvertimeObject.Type? = User.self
    public func objects() -> [Object] {
        [user]
    }

    public var user: UserResponse
}

public struct UserResponse: UserRepresentableResponse {
    public var id: String
    var dynamodb_id: String?
    var uuid: String?
    var name: String?
    var bio: String?
    var username: String?
    var instagram_id: String?
    var image_path: String?
    var location: String?
    var avatar_id: String?
    var total_coins: Int?
    var total_potential_coins: Int?
    var total_wagered_coins: Int?
    var total_experience_points: Int?
    var current_experience_level_id: String?
    var factual_question_pools_joined_count: Int?

    var phone_verified: Bool
    var device_ids: [String]?
    var camera_tos_agreed_at: Date?
    var scores_tos_agreed_at: Date?
    var roles: [String]?
    var is_camera_requested: Bool?
    var is_camera_authorized: Bool?
    var is_camera_rejected: Bool?
    var prioritized_headline_tags: [String]?
    var is_banned: Bool?
    var is_username_change_required: Bool?
    var is_name_change_required: Bool?
    var is_image_change_required: Bool?
    var is_bio_change_required: Bool?
    var is_comment_acknowledge_required: Bool?
    var is_trusted_scores_host: Bool?
    var is_bets_requested: Bool?
    var is_bets_granted: Bool?
}

protocol UserRepresentableResponse: OvertimeDecodable {
    var id: String { get }
    var dynamodb_id: String? { get }
    var uuid: String? { get }
    var name: String? { get }
    var bio: String? { get }
    var username: String? { get }
    var instagram_id: String? { get }
    var image_path: String? { get }
    var location: String? { get }
    var avatar_id: String? { get }
    var total_coins: Int? { get }
    var total_potential_coins: Int? { get }
    var total_wagered_coins: Int? { get }
    var total_experience_points: Int? { get }
    var current_experience_level_id: String? { get }
    var factual_question_pools_joined_count: Int? { get }
    var is_trusted_scores_host: Bool? { get }
    var is_bets_requested: Bool? { get }
    var is_bets_granted: Bool? { get }
}

public struct SparseUserResponse: UserRepresentableResponse {
    public var id: String
    var dynamodb_id: String?
    var uuid: String?
    var name: String?
    var bio: String?
    var username: String?
    var instagram_id: String?
    var image_path: String?
    var location: String?
    var avatar_id: String?
    var total_coins: Int?
    var total_potential_coins: Int?
    var total_wagered_coins: Int?
    var total_experience_points: Int?
    var current_experience_level_id: String?
    var factual_question_pools_joined_count: Int?
    var is_trusted_scores_host: Bool?
    var is_bets_requested: Bool?
    var is_bets_granted: Bool?
}

public struct UserNotificationTypesFetchResponse: FetchResponse {
    public static var model: OvertimeObject.Type? = nil

    public typealias Object = String
    public func objects() -> [Object] {
        notification_types
    }

    public var notification_types: [Object]
}

public class User: OvertimeObject {
    @Persisted var dynamodb_id : String = ""
    @Persisted public var uuid : String = ""
    @Persisted public var username : String?
    @Persisted public var name : String?
    @Persisted public var bio : String?
    @Persisted public var instagram_id: String?
    @Persisted public var image_path: String?
    @Persisted public var avatar_id: String?
    @Persisted public var camera_tos_agreed_at: Date?
    @Persisted public var scores_tos_agreed_at: Date?
    @Persisted public var phone_verified = false
    @Persisted public var is_camera_authorized = false
    @Persisted public var is_camera_requested = false
    @Persisted public var is_camera_rejected = false
    @Persisted public var is_banned = false
    @Persisted public var is_username_change_required = false
    @Persisted public var is_name_change_required = false
    @Persisted public var is_image_change_required = false
    @Persisted public var is_bio_change_required = false
    @Persisted public var is_comment_acknowledge_required = false
    @Persisted public var is_trusted_scores_host = false
    @Persisted public var is_bets_requested = false
    @Persisted public var is_bets_granted = false

    @Persisted public var location: String?
    @Persisted public var roles: List<String>
    @Persisted var device_ids: List<String>
    @Persisted public var total_coins : Int = 0
    @Persisted public var total_wagered_coins : Int = 0
    @Persisted public var total_potential_coins : Int = 0
    @Persisted public var total_experience_points : Int = 0
    @Persisted public var current_experience_level_id: String?
    @Persisted public var consecutive_days_started_at: Date?
    @Persisted public var prioritized_headline_tags: List<String>
    @Persisted public var factual_question_pools_joined_count: Int = 0

    @Persisted public var notification_types: List<String>
    @Persisted public var favorite_team_ids: List<String>

    var sentMessages = LinkingObjects(fromType: Message.self, property: "from_user")

    public override func updateFrom(_ from: OvertimeDecodable) {
        super.updateFrom(from)

        if let from = from as? SparseUserResponse {
            updateFrom(from)
        } else if let from = from as? UserResponse {
            updateFrom(from)
        }
    }

    func updateFrom(_ from: UserRepresentableResponse) {
        uuid = from.uuid ?? from.id
        dynamodb_id = from.dynamodb_id ?? dynamodb_id
        username = from.username ?? username
        name = from.name ?? name
        bio = from.bio ?? bio
        instagram_id = from.instagram_id ?? instagram_id
        location = from.location
        image_path = from.image_path
        avatar_id = from.avatar_id ?? avatar_id
        current_experience_level_id = from.current_experience_level_id ?? current_experience_level_id
        total_coins = from.total_coins ?? total_coins
        total_potential_coins = from.total_potential_coins ?? total_potential_coins
        total_wagered_coins = from.total_wagered_coins ?? total_wagered_coins
        total_experience_points = from.total_experience_points ?? total_experience_points
        factual_question_pools_joined_count = from.factual_question_pools_joined_count ?? factual_question_pools_joined_count
        is_trusted_scores_host = from.is_trusted_scores_host ?? is_trusted_scores_host
        is_bets_requested = from.is_bets_requested ?? is_bets_requested
        is_bets_granted = from.is_bets_granted ?? is_bets_granted
    }

    func updateFrom(_ from: SparseUserResponse) {
        updateFrom(from as UserRepresentableResponse)
    }

    func updateFrom(_ from: UserResponse) {
        updateFrom(from as UserRepresentableResponse)

        phone_verified = from.phone_verified
        camera_tos_agreed_at = from.camera_tos_agreed_at
        scores_tos_agreed_at = from.scores_tos_agreed_at
        is_camera_authorized = from.is_camera_authorized ?? is_camera_authorized
        is_camera_requested = from.is_camera_requested ?? is_camera_requested
        is_camera_rejected = from.is_camera_rejected ?? is_camera_rejected
        is_banned = from.is_banned ?? is_banned
        is_username_change_required = from.is_username_change_required ?? is_username_change_required
        is_name_change_required = from.is_name_change_required ?? is_name_change_required
        is_image_change_required = from.is_image_change_required ?? is_image_change_required
        is_bio_change_required = from.is_bio_change_required ?? is_bio_change_required
        is_comment_acknowledge_required = from.is_comment_acknowledge_required ?? is_comment_acknowledge_required
        is_trusted_scores_host = from.is_trusted_scores_host ?? is_trusted_scores_host
        is_bets_requested = from.is_bets_requested ?? is_bets_requested
        is_bets_granted = from.is_bets_granted ?? is_bets_granted
        device_ids.removeAll()
        device_ids.append(objectsIn: from.device_ids ?? [])
        if let fromRoles = from.roles {
            roles.removeAll()
            roles.append(objectsIn: fromRoles)
        }
        if let tags = from.prioritized_headline_tags {
            prioritized_headline_tags.removeAll()
            prioritized_headline_tags.append(objectsIn: tags)
        }
    }
}

