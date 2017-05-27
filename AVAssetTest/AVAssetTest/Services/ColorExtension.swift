//
//  ColorExtension.swift
//  VideoTest
//
//  Created by seo on 2017. 5. 9..
//  Copyright © 2017년 seoju. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex16: UInt16) {
        let alpha = CGFloat((hex16 >> 12) & 0xf) / 0xf
        let red = CGFloat((hex16 >> 8) & 0xf) / 0xf
        let green = CGFloat((hex16 >> 4) & 0xf) / 0xf
        let blue = CGFloat(hex16 & 0xf) / 0xf
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    convenience init (hex32: UInt32) {
        let alpha = CGFloat((hex32 >> 24) & 0xff) / 0xff
        let red = CGFloat((hex32 >> 16) & 0xff) / 0xff
        let green = CGFloat((hex32 >> 8) & 0xff) / 0xff
        let blue = CGFloat(hex32 & 0xff) / 0xff
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    convenience init (hex32: UInt32, alpha: CGFloat) {
        let red = CGFloat((hex32 >> 16) & 0xff) / 0xff
        let green = CGFloat((hex32 >> 8) & 0xff) / 0xff
        let blue = CGFloat(hex32 & 0xff) /
        0xff
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    convenience init?(hexString: String) {
        if !hexString.hasPrefix("#") {
            return nil
        }
        var hexStr = hexString
        hexStr.remove(at: hexStr.startIndex)
        switch hexStr.characters.count {
        case 3:
            hexStr = "f" + hexStr
            fallthrough
        case 4:
            guard let hex16 = UInt16(hexStr, radix: 16) else {
                return nil
            }
            self.init(hex16: hex16)
        case 6:
            hexStr = "ff" + hexStr
            fallthrough
        case 8:
            guard let hex32 = UInt32(hexStr, radix: 16) else {
                return nil
            }
            self.init(hex32: hex32)
        default:
            return nil
        }
    }
    
    func isSameTwoColor(_ color: UIColor) -> Bool {
        
        // 입실론을 이용해서 데이터 비교
        // 부동소수점 오류
        let epsilon:CGFloat = 0.000001
        // 생성되는 버튼의 rgb값
        let rgb1 = self.cgColor.components
        // 사용자가 저장한 rgb값
        let rgb2 = color.cgColor.components
        
        if (fabs((rgb1?[0])!-(rgb2?[0])! ) < epsilon) && (fabs((rgb1?[1])!-(rgb2?[1])!) < epsilon) && (fabs((rgb1?[2])!-(rgb2?[2])!) < epsilon) {
            return true
        } else {
            return false
        }
    }
    
    func isEqualWithConversion(_ color: UIColor) -> Bool {
        guard let space = self.cgColor.colorSpace
            else { return false }
        guard let converted = color.cgColor.converted(to: space, intent: .absoluteColorimetric, options: nil)
            else { return false }
        return self.cgColor == converted
    }
}
