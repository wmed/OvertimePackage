//
//  StringExtensions.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Foundation

public extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}


// TODO: move to package
public extension String {
    var numerics: String {
        return self.filter("01234567890".contains)
    }
}
