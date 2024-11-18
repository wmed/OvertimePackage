//
//  OvertimeObject.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation
import RealmSwift

public protocol OvertimeDecodable: Decodable {
    var id: String { get }
}

public protocol OvertimeObjectProtocol: AnyObject  {
    static func findOrCreate(id: String) -> Self
    static func from(_ from: OvertimeDecodable) -> Self
}

open class OvertimeObject: RealmSwift.Object, OvertimeObjectProtocol, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id : String?

    override public required init() {
    }

    public static func findOne(_ id: String?) -> Self? {
        try? Realm().object(ofType: Self.self, forPrimaryKey: id)
    }

    public static func find<Self: OvertimeObject>() -> Results<Self>? {
        try? Realm().objects(Self.self)
    }

    public static func find<Self: OvertimeObject>(_ predicate: NSPredicate) -> Results<Self>? {
        try? Realm().objects(Self.self).filter(predicate)
    }

    public static func find<Self: OvertimeObject>(_ predicateFormat:String, _ args: Any...) -> Results<Self>? {
        try? Realm().objects(Self.self).filter(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    public static func findOrCreate(id: String) -> Self {
        let realm = try! Realm()
        if let object = findOne(id) {
            return object
        } else {
            let object = self.init()
            object.id = id
            if realm.isInWriteTransaction {
                realm.add(object, update: .modified)
            } else {
                try! realm.write {
                    realm.add(object, update: .modified)
                }
            }
            return object
        }
    }

    public static func from(_ from: OvertimeDecodable) -> Self {
        let object = Self.findOrCreate(id: from.id)
        let realm = try! Realm()
        if realm.isInWriteTransaction {
            object.updateFrom(from)
        } else {
            try! realm.write {
                object.updateFrom(from)
            }
        }
        return object 
    }

    open func updateFrom(_ from: OvertimeDecodable) {
        if isInvalidated { return }
    }
}

extension OvertimeObject {
    @MainActor
    public static func findOne(_ id: String?) async -> Self? {
        try? await Realm().object(ofType: Self.self, forPrimaryKey: id)?.freeze()
    }

    @MainActor
    public static func findAll<Self: OvertimeObject>() async -> Results<Self>? {
        try? await Realm().objects(Self.self).freeze()
    }

    @MainActor
    public static func findAll<Self: OvertimeObject>(_ predicate:NSPredicate) async -> Results<Self>? {
        try? await Realm().objects(Self.self).filter(predicate).freeze()
    }

    @MainActor
    public static func findAll<Self: OvertimeObject>(_ predicateFormat:String, _ args: Any...) async -> Results<Self>? {
        try? await Realm().objects(Self.self).filter(NSPredicate(format: predicateFormat, argumentArray: args)).freeze()
    }

    @MainActor
    public static func findOrCreate(id: String) async throws -> Self {
        let realm = try await Realm()
        if let object = await findOne(id) {
            return object
        } else {
            let object = self.init()
            object.id = id
            if realm.isInWriteTransaction {
                realm.add(object, update: .modified)
            } else {
                try! realm.write {
                    realm.add(object, update: .modified)
                }
            }
            return object.freeze()
        }
    }

    @MainActor
    public func asyncWrite(update: () -> (Void)) async throws {
        let object = isFrozen ? thaw() : self
        try await object?.realm?.loggedAsyncWrite(update: update)
    }

    public func syncWrite(update: () -> (Void)) throws {
        let object = isFrozen ? thaw() : self
        try object?.realm?.loggedWrite(update: update)
    }
}
