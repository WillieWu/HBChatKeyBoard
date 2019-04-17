//
//  APTextView.swift
//  ap
//
//  Created by 伍宏彬 on 2018/5/4.
//  Copyright © 2018年 whb. All rights reserved.
//

import UIKit

public typealias HBChatTextHeightChangeBlock = () -> Void

public class HBChatTextView: UITextView {
    
    public var maxLine: Int = 4
    public var placeholderText: String = "写点什么……" {
        didSet {
            self.placeholderView.text = placeholderText
        }
    }
    public var placeholderColor: UIColor = UIColor.lightGray {
        didSet {
            self.placeholderView.textColor = placeholderColor
        }
    }
    public var textHeightBlock: HBChatTextHeightChangeBlock?
    public var textHeight: CGFloat = 0
    public var sendAction: ((_ text: String) -> ())?
    
    fileprivate var maxTextHeight: CGFloat {
        get {
            return (self.font?.lineHeight)! * CGFloat(maxLine) + self.textContainerInset.top + self.textContainerInset.bottom
        }
    }
    
    fileprivate lazy var placeholderView: UITextView = {
        let tv = UITextView()
        tv.showsVerticalScrollIndicator = false
        tv.showsHorizontalScrollIndicator = false
        tv.isUserInteractionEnabled = false
        tv.font = self.font
        tv.textColor = UIColor.lightGray
        tv.backgroundColor = UIColor.clear
        return tv
    }()
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.scrollsToTop = false
        self.showsHorizontalScrollIndicator = false
        self.enablesReturnKeyAutomatically = true
        self.layer.cornerRadius = 5
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1.0
        self.font = UIFont.systemFont(ofSize: 15)
        self.returnKeyType = .send
        self.delegate = self as UITextViewDelegate
        self.addSubview(self.placeholderView)
        //TODO: @whb 设置字行距
//        let lineStyle = NSMutableParagraphStyle()
//        lineStyle.lineSpacing = 15
//        self.typingAttributes = [NSAttributedString.Key.paragraphStyle: lineStyle.copy()]
        
        NotificationCenter.default.addObserver(self, selector: #selector(HBChatTextView.p_textViewTextChange), name: NSNotification.Name.UITextViewTextDidChange, object: nil)
        self.addObserver(self, forKeyPath: "attributedText", options: [.new, .old], context: nil)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.placeholderView.frame = self.bounds
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath! == "attributedText" {
            self.p_textViewTextChange()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc fileprivate func p_textViewTextChange() {
        self.placeholderView.isHidden = self.text.count > 0 || self.attributedText.length > 0
        let height = self.sizeThatFits(CGSize(width: self.bounds.size.width, height: CGFloat(MAXFLOAT))).height
        guard self.textHeight != height else { return }
        guard height <= self.maxTextHeight else { return }
        self.textHeight = height
        self.textHeightBlock?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.removeObserver(self, forKeyPath: "attributedText")
    }
}

extension HBChatTextView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.sendAction?(self.attributedText.hb_toString() as String)
            self.text = nil
            return false
        }
        return true
    }
}

