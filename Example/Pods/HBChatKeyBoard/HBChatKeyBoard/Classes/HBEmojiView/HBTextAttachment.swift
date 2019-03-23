//
//  HBTextAttachment.swift
//  HBChatKeyBoard_Example
//
//  Created by 伍宏彬 on 2019/3/5.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

fileprivate let regularExpression: NSRegularExpression = try! NSRegularExpression(pattern: "\\[[a-zA-Z0-9\\u4e00-\\u9fa5/]+\\]", options: NSRegularExpression.Options.caseInsensitive)

public extension NSString {
    public func hb_toAttributeString(_ font: UIFont = UIFont.systemFont(ofSize: 15)) -> NSAttributedString {
        let allString = self as String
        let attributeString = NSMutableAttributedString(string: self as String)
        attributeString.setAttributes([NSAttributedStringKey.font: font], range: NSRange(location: 0, length: allString.count))
        let matches = regularExpression.matches(in: allString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: allString.count))
        for result in matches.reversed() {
            let emjoyStr = self.substring(with: result.range) as NSString
            let range = emjoyStr.range(of: "[/")
            let loc = range.location + range.length
            let len = emjoyStr.range(of: "]").location
            let emjoyName = emjoyStr.substring(with: NSRange(location: loc, length: len - loc))
            
            let textAtt = HBTextAttachment.createAttachment()
            textAtt.emojiName = emjoyName
            textAtt.image = UIImage.hb_imageName(name: emjoyName)
            let imageString = NSMutableAttributedString(attachment: textAtt)
            imageString.append(NSAttributedString(string: " "))
            attributeString.replaceCharacters(in: result.range, with: imageString)
        }
        return attributeString
    }
}

public extension NSAttributedString {
    public func hb_toString() -> NSString {
        let allString = NSMutableString()
        self.enumerateAttributes(in: NSMakeRange(0, self.length), options: NSAttributedString.EnumerationOptions.longestEffectiveRangeNotRequired) { (attrs, range, stop) in
            let hbTextAtt = attrs[NSAttributedString.Key.attachment] as? HBTextAttachment
            if hbTextAtt != nil {
                allString.append("[/\(hbTextAtt!.emojiName)]")
            } else {
                allString.append(self.attributedSubstring(from: range).string)
            }
        }
        return allString.copy() as! NSString
    }
}

public class HBTextAttachment: NSTextAttachment {
    public var emojiName: String = ""
//    var emojiRange: NSRange = NSRange(location: 0, length: 0)
    
    public class func createAttachment() -> HBTextAttachment {
        let textAtt = HBTextAttachment()
        textAtt.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
        return textAtt
    }
}
