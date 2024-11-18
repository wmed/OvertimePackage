//
//  UserAvatar.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import RealmSwift

public struct UserAvatarResponse: OvertimeDecodable {
    public var id: String
    public var user_id: String
    public var avatar_id: String
}

public class UserAvatar: OvertimeObject {
    @Persisted public var avatar_id : String?
    @Persisted public var user_id: String?
    @Persisted public var avatar: Avatar?

    override public func updateFrom(_ from: OvertimeDecodable) {
        super.updateFrom(from)

        guard let from = from as? UserAvatarResponse else { return }

        user_id = from.user_id
        avatar_id = from.avatar_id
        avatar = try? Realm().object(ofType: Avatar.self, forPrimaryKey: avatar_id)
    }
}
