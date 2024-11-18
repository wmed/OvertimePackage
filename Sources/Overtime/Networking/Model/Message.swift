//
//  Message.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation
import RealmSwift

@available(*, deprecated, message: "Marked for deprecation - Likely no longer in use")
public class Message: RealmSwift.Object {
    @objc dynamic public var id: String?
    @objc dynamic public var client_id: String?
    @objc dynamic public var created_at: Date?
    @objc dynamic public var updated_at: Date?
    @objc dynamic public var text: String?
    @objc dynamic public var from_user: User?
    @objc dynamic public var to_user: User?
    @objc dynamic public var readAt: Date?

    override public static func primaryKey() -> String? {
        return "id"
    }
}
