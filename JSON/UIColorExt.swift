//
//  UIColorExt.swift
//  JSON
//
//  Created by Juan Alvarez on 3/26/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import UIKit

extension UIColor {
    
    public class func fromRGB(r: Int, _ g: Int, _ b: Int) -> UIColor {
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1)
    }
    
    public class func fromHex(hex: String) -> UIColor {
        var str = hex.uppercaseString
        
        if str.hasPrefix("#") {
            str = str.substring(1..<str.characters.count)!
        }
        
        if str.characters.count != 6 {
            fatalError("hex must have 6 charachters: \(hex)")
        }
        
        var r: UInt32 = 0
        var g: UInt32 = 0
        var b: UInt32 = 0
        
        NSScanner(string: str.substring(0...1)!).scanHexInt(&r)
        NSScanner(string: str.substring(2...3)!).scanHexInt(&g)
        NSScanner(string: str.substring(4...5)!).scanHexInt(&b)
        
        return fromRGB(Int(r), Int(g), Int(b))
    }
}