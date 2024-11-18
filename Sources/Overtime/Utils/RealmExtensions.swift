//
//  RealmExtensions.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import RealmSwift

extension Realm {
    public func loggedWrite(update: () -> (Void), logManager: LogManaging = DefaultLogManager()) throws {
        do {
            if isInWriteTransaction {
                update()
            } else {
                try write { update() }
            }
        } catch let error {
            logManager.log(error: error, description: "Failed to write to realm")
            throw error
        }
    }

    // Esnures writes in async functions are ran on Main thread
    @MainActor
    public func loggedAsyncWrite(update: () -> (Void), logManager: LogManaging = DefaultLogManager()) async throws {
        do {
            try await asyncWrite { update() }
        } catch let error {
            logManager.log(error: error, description: "Failed to write to realm")
            throw error
        }
    }

    @MainActor
    @available(*, deprecated, renamed: "loggedAsyncWrite")
    public func overtimeAsyncWrite(update: () -> (Void)) async throws {
        try await loggedAsyncWrite(update: update)
    }
}

@MainActor
@available(*, deprecated, message: "Use loggedAsyncWrite on Realm object with async/await")
public func asyncRealmWrite(update: () -> (Void)) async throws {
    do {
        let realm = try await Realm()
        try await realm.loggedAsyncWrite {
           update()
        }
    } catch {
        throw error
    }
}

// Temporarily needed for when Realm hadn't fixed their async/await due to changes in Swift 5.7
// With latest Realm update should now upgarde to use async/await and use `loggedWrite` on Realm object
@available(*, deprecated, message: "Use loggedWrite on Realm object with async/await")
public func syncRealmWrite(update: () -> (Void)) throws -> Bool {
    let realm = try Realm(queue: nil)
    if realm.isInWriteTransaction {
        update()
    } else {
        try realm.write {
           update()
        }
    }

    return true
}
