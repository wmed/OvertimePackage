//
//  ArrayExtensions.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation
import RealmSwift

extension Array {
    public func valueAtIndex(_ index: Int) -> Element? {
        if index < 0 {
            return nil
        }
        if index > count - 1 {
            return nil
        }
        return self[index]
    }
}

extension Results {
    public func objectAtIndex(_ index: Int) -> Element? {
        if isInvalidated {
            return nil
        }
        if index < 0 {
            return nil
        }
        if index > count - 1 {
            return nil
        }
        return self[index]
    }
}

extension List {
    public func objectAtIndex(_ index: Int) -> Element? {
        if isInvalidated {
            return nil
        }
        if index < 0 {
            return nil
        }
        if index > count - 1 {
            return nil
        }
        return self[index]
    }
}
