//
//  StringExt.swift
//  JSON
//
//  Created by Juan Alvarez on 4/5/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

extension String {
    
    func substring(from: Int, to: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        let end = index(start, offsetBy: to - from)
        
        return String(self[start..<end])
    }
    
    func substring(range: Range<Int>) -> String {
        return self.substring(from: range.lowerBound, to: range.upperBound)
    }
}
