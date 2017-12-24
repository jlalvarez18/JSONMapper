//
//  UIColorExt.swift
//  JSON
//
//  Created by Juan Alvarez on 3/26/15.
//  Copyright (c) 2015 Alvarez Productions. All rights reserved.
//

import UIKit

extension UIColor {
    
    public class func fromRGB(r: Int, g: Int, b: Int) -> UIColor {
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1)
    }
    
    public class func fromHex(hex: String) -> UIColor {
        var str = hex.uppercased()
        
        if str.hasPrefix("#") {
            str = str.substring(range: 1..<str.count)
        }
        
        if str.count != 6 {
            fatalError("hex must have 6 charachters: \(hex)")
        }
        
        var r: UInt32 = 0
        var g: UInt32 = 0
        var b: UInt32 = 0
        
        Scanner(string: str.substring(range: Range(0...1))).scanHexInt32(&r)
        Scanner(string: str.substring(range: Range(2...3))).scanHexInt32(&g)
        Scanner(string: str.substring(range: Range(4...5))).scanHexInt32(&b)
        
        return fromRGB(r: Int(r), g: Int(g), b: Int(b))
    }
}
