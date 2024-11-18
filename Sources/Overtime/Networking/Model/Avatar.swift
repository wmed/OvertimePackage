//
//  Avatar.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation
import RealmSwift

public struct AvatarResponse: OvertimeDecodable {
    public var id: String
    public var created_at: Date?
    public var cost: Int?
    public var is_listed: Bool?
    public var is_initial: Bool?
    public var name: String?
    public var image_path: String?
    public var image_placeholder_color: Int?
    public var required_experience_level_id: String?
    public var user_avatars: [UserAvatarResponse]?
}

public class Avatar: OvertimeObject {
    @Persisted public var created_at: Date?
    @Persisted var is_listed = true
    @Persisted var is_initial = false
    @Persisted public var name: String?
    @Persisted public var image_path : String?
    public var imageUrl: URL? {
        guard let image_path = image_path else { return nil }
        return URL(string: "https://images.overtime.tv/avatars/\(image_path)?width=\(240))?format=png")
    }
    @Persisted public var cost : Int = 0
    @Persisted var imagePlaceholderColorInt: Int = 0
    @Persisted public var isUnlocked = false
    @Persisted public var required_experience_level_id: String?
//    var requiredExperienceLevel: ExperienceLevel? {
    //NOTE: Disabling this for now since we're not using it and want to get Avatar into the pod easily for
    //better avatar view loading
//        return nil
//        guard let id = required_experience_level_id else { return nil }
//        return try! Realm().object(ofType: ExperienceLevel.self, forPrimaryKey: id)
//    }
    @Persisted var requiredExperiencePoints = 0


    override public func updateFrom(_ from: OvertimeDecodable) {
        super.updateFrom(from)

        guard let from = from as? AvatarResponse else { return }

        created_at = from.created_at
        is_listed = from.is_listed ?? is_listed
        is_initial = from.is_initial ?? is_initial
        name = from.name
        image_path = from.image_path
        cost = from.cost ?? 0
        imagePlaceholderColorInt = from.image_placeholder_color ?? 0
        required_experience_level_id = from.required_experience_level_id
        isUnlocked = from.user_avatars?.count ?? 0 > 0
//        if let required_experience_level_id = from.required_experience_level_id {
//            requiredExperiencePoints = (try? Realm().object(ofType: ExperienceLevel.self, forPrimaryKey: required_experience_level_id)?.experience_points_required) ?? 0
//        }
    }
}
