//
//  NSNumberExt.swift
//  JSON
//
//  Created by Juan Alvarez on 3/26/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

private let trueNumber = NSNumber(bool: true)
private let falseNumber = NSNumber(bool: false)
private let trueObjCType = String.fromCString(trueNumber.objCType)
private let falseObjCType = String.fromCString(falseNumber.objCType)

extension NSNumber {
    
    func isBool() -> Bool {
        let objCType = String.fromCString(self.objCType)
        
        let trueNumberComparison = (self.compare(trueNumber) == NSComparisonResult.OrderedSame && objCType == trueObjCType)
        let falseNumberComparison = (self.compare(falseNumber) == NSComparisonResult.OrderedSame && objCType == falseObjCType)
        
        if trueNumberComparison || falseNumberComparison {
            return true
        } else {
            return false
        }
    }
}