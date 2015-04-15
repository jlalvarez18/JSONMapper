//
//  StringExt.swift
//  JSON
//
//  Created by Juan Alvarez on 4/5/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import Foundation

extension String {
    
    func substring(range: Range<Int>) -> String? {
        if range.startIndex < 0 || range.endIndex > count(self) {
            return nil
        }
        
        let range = Range(start: advance(startIndex, range.startIndex), end: advance(startIndex, range.endIndex))
        
        return self[range]
    }
}