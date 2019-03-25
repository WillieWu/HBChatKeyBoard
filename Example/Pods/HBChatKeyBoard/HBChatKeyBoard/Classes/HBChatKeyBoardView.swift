//
//  HBChatKeyBoardView.swift
//  HBChatKeyBoard
//
//  Created by 伍宏彬 on 2019/2/28.
//

import UIKit
import SnapKit

var kHBChatKeyBoardViewHeight: CGFloat {
    get {
        var safeBottom: CGFloat = 0
        if #available(iOS 11.0, *) {
            var window = UIApplication.shared.keyWindow
            if window == nil { window = UIWindow() }
            safeBottom = window!.safeAreaInsets.bottom
        }
        return kHBChatKeyBoardViewBarHeight + safeBottom
    }
}

fileprivate let kHBChatKeyBoardViewBarHeight: CGFloat = 52
fileprivate let kHBChatKeyBoardViewPadding: CGFloat = 8

public typealias HBChatKeyBoardTextChangeBlock = (_ textChange: String) -> Void
public typealias HBChatKeyBoardSendBlock = (_ textChange: String) -> Void

public class HBChatKeyBoardView: UIView {
    public class func keyBoardView() -> HBChatKeyBoardView {
        return HBChatKeyBoardView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: kHBChatKeyBoardViewHeight))
    }
    public var textChangeBlock: HBChatKeyBoardTextChangeBlock?
    public var sendTextBlock: HBChatKeyBoardSendBlock?
    public var keyBoardViewHeightChange: ((_ height: CGFloat) -> ())?
    
    fileprivate lazy var barView: UIView = {
        let tl = UIView()
        return tl
    }()
    
    fileprivate lazy var voiceButton: UIButton = {
        let tl = UIButton(type: UIButtonType.custom)
        tl.setBackgroundImage(UIImage.hb_imageName(name: "bar_mirco.png"), for: .normal)
        tl.setBackgroundImage(UIImage.hb_imageName(name: "bar_keyboard.png"), for: .selected)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_voiceButtonAction(_:)), for: .touchUpInside)
        return tl
    }()
    
    fileprivate lazy var emojiButton: UIButton = {
        let tl = UIButton(type: UIButtonType.custom)
        tl.setBackgroundImage(UIImage.hb_imageName(name: "bar_emoj.png"), for: .normal)
        tl.setBackgroundImage(UIImage.hb_imageName(name: "bar_keyboard.png"), for: .selected)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_emojiButtonAction(_:)), for: .touchUpInside)
        return tl
    }()
    
    fileprivate lazy var addButton: UIButton = {
        let tl = UIButton(type: UIButtonType.custom)
        tl.setImage(UIImage.hb_imageName(name: "bar_add.png"), for: .normal)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_addButtonAction(_:)), for: .touchUpInside)
        return tl
    }()
    
    fileprivate lazy var pressRecordButton : UIButton = {
        let tl = UIButton(type: UIButtonType.custom)
        tl.setTitle("按住说话", for: UIControlState.normal)
        tl.setTitleColor(UIColor.black, for: UIControlState.normal)
        tl.setBackgroundImage(UIImage.hb_image(fromColor: UIColor.gray), for: .highlighted)
        tl.setBackgroundImage(UIImage.hb_image(fromColor: UIColor.white), for: .normal)
        tl.backgroundColor = UIColor.white
        tl.layer.cornerRadius = 4.0
        tl.layer.masksToBounds = true
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_recordStarAction(_:)), for: .touchDown)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_recordStarAction(_:)), for: .touchDragEnter)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_recordStopAction(_:)), for: .touchUpInside)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_recordPrepareAction(_:)), for: .touchDragExit)
        tl.addTarget(self, action: #selector(HBChatKeyBoardView.p_recordCancleAction(_:)), for: .touchUpOutside)
        tl.isHidden = true
        return tl
    }()
    
    fileprivate lazy var emojiView: HBEmojiView = {
        let tl = HBEmojiView.emojiView()
        tl.selectEmoji = { (textAtt) in
            let emojiAtt = NSMutableAttributedString(attachment: textAtt)
            emojiAtt.append(NSAttributedString(string: " "))
            let textViewAtt = NSMutableAttributedString(attributedString: self.textView.attributedText)
            let insetIndex = self.textView.selectedRange.location
            textViewAtt.insert(emojiAtt, at: insetIndex)
            textViewAtt.addAttribute(NSAttributedString.Key.font, value: self.textView.font as Any, range: NSRange(location: 0, length: textViewAtt.length))
            self.textView.attributedText = textViewAtt
            self.textView.selectedRange.location = insetIndex + 1 + 1
        }
        tl.selectPicture = { (model) in
            print("图片名称：\(model.emojiName)")
        }
        tl.deleteAction = {
            self.textView.deleteBackward()
        }
        tl.clearAction = {
            self.textView.text = nil
        }
        tl.sendAction = {
            self.sendTextBlock?(self.textView.attributedText.hb_toString() as String)
            self.textView.text = nil
        }
        
        return tl
    }()
    
    fileprivate lazy var moreMenuView: HBMoreMenuView = {
        let tl = HBMoreMenuView.menuView()
        return tl
    }()
    
    fileprivate lazy var textView: HBChatTextView = {
        let tl = HBChatTextView()
        tl.sendAction = { (text) in
            self.sendTextBlock?(text)
        }
        tl.textHeightBlock = { [weak self] in
            guard let `self` = self else { return }
            self.p_reloadHeight()
        }
        tl.backgroundColor = UIColor.white
        return tl
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.barView)
        self.barView.addSubview(self.voiceButton)
        self.barView.addSubview(self.textView)
        self.barView.addSubview(self.emojiButton)
        self.barView.addSubview(self.addButton)
        self.barView.addSubview(self.pressRecordButton)
        
        self.barView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(-(self.frame.size.height - kHBChatKeyBoardViewBarHeight))
            } else {
                make.bottom.equalToSuperview()
            }
        }
        
        self.voiceButton.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.bottom.equalTo(-12)
            make.width.height.equalTo(kHBChatKeyBoardViewBarHeight - 12 * 2)
        }
        self.addButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.voiceButton.snp.centerY)
            make.right.equalTo(-12)
            make.size.equalTo(self.voiceButton)
        }
        self.emojiButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.voiceButton.snp.centerY)
            make.size.equalTo(self.voiceButton)
            make.right.equalTo(self.addButton.snp.left).offset(-10)
        }
        self.textView.snp.makeConstraints { (make) in
            make.top.equalTo(kHBChatKeyBoardViewPadding)
            make.left.equalTo(self.voiceButton.snp.right).offset(kHBChatKeyBoardViewPadding)
            make.right.equalTo(self.emojiButton.snp.left).offset(-kHBChatKeyBoardViewPadding)
            make.bottom.equalToSuperview().offset(-kHBChatKeyBoardViewPadding)
        }
        self.pressRecordButton.snp.makeConstraints { (make) in
            make.size.equalTo(self.textView)
            make.center.equalTo(self.textView)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidHide, object: nil, queue: nil) { (info) in
            self.textView.inputView = nil
            for changeButton in [self.voiceButton, self.emojiButton, self.addButton] {
                guard changeButton.isSelected && changeButton != self.voiceButton else { continue }
                changeButton.isSelected = false
            }
        }
        
        // 加载本地plist表情数据
        p_clipArrayWithSection()
        
        // 加载更多功能中的数据
        p_loadMoreItem()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//MARK: Action
extension HBChatKeyBoardView {
    @objc fileprivate func p_voiceButtonAction(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        p_buttonExchangeSelect(btn)
        if btn.isSelected {
            self.textView.inputView = nil
            self.textView.resignFirstResponder()
        } else {
            self.textView.becomeFirstResponder()
        }
    }
    @objc fileprivate func p_emojiButtonAction(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        p_buttonExchangeSelect(btn)
        self.textView.inputView = btn.isSelected ? self.emojiView : nil
        self.textView.reloadInputViews()
        self.textView.becomeFirstResponder()
    }
    @objc fileprivate func p_addButtonAction(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        p_buttonExchangeSelect(btn)
        self.textView.inputView = btn.isSelected ? self.moreMenuView : nil
        self.textView.reloadInputViews()
        self.textView.becomeFirstResponder()
    }
    
    @objc fileprivate func p_recordStarAction(_ btn: UIButton) {
        print("开始录音")
        HBRecordTool.default.startRecord(speakerVaule: { (mute) in
            print("分贝：\(mute)")
        }, currentRecord: { (recordTime) in
            print("当前录音时间：\(recordTime)")
        }, maxSecond: { (audioURL, audioSec) in
            print("最大录音时间到：\(audioURL) \n \(audioSec)")
        }) {
            print("录音时间太短")
        }
    }
    @objc fileprivate func p_recordPrepareAction(_ btn: UIButton) {
        print("准备放弃录音")
    }
    @objc fileprivate func p_recordStopAction(_ btn: UIButton) {
        print("停止录音")
        HBRecordTool.default.stopRecord { (fileURL, fileSecond) in
            print("录音文件：\(fileURL.absoluteString), 录音时间：\(fileSecond)")
        }
    }
    @objc fileprivate func p_recordCancleAction(_ btn: UIButton) {
        print("放弃本次录音")
        HBRecordTool.default.deleteRecord()
    }
    fileprivate func p_buttonExchangeSelect(_ btn: UIButton) {
        for changeButton in [self.voiceButton, self.emojiButton, self.addButton] {
            guard changeButton.isSelected && btn != changeButton else { continue }
            changeButton.isSelected = false
            break
        }
        self.pressRecordButton.isHidden = !self.voiceButton.isSelected;
        p_reloadHeight()
    }
    fileprivate func p_reloadHeight() {
        if self.pressRecordButton.isHidden {
            let height = max(self.textView.textHeight + kHBChatKeyBoardViewPadding * 2, kHBChatKeyBoardViewBarHeight)
            self.keyBoardViewHeightChange?(height + kHBChatKeyBoardViewHeight - kHBChatKeyBoardViewBarHeight)
        } else {
            self.keyBoardViewHeightChange?(kHBChatKeyBoardViewHeight)
        }
    }
}

extension UIImage {
    class func hb_imageName(name: String) -> UIImage? {
        let imagePath = UIImage.hb_imagePath(name)
        return UIImage(contentsOfFile: imagePath ?? "")
    }
    
    class func hb_imagePath(_ imageName: String) -> String? {
        var fixName = imageName
        if !fixName.hasSuffix(".png") {
            fixName.append(".png")
        }
        let mainImagePath = Bundle.main.path(forResource: fixName, ofType: nil)
        guard mainImagePath == nil else {
            return mainImagePath
        }
        return HBBundle.path(forFile: fixName)
    }
    
    class func hb_image(fromColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

public class HBBundle: NSObject {
    public static let `default`: HBBundle = HBBundle()
    private var currentBundle: Bundle?
    
    public override init() {
        super.init()
        let currentBundlePath = Bundle(for: HBChatKeyBoardView.self).path(forResource: "HBChatKeyBoard", ofType: "bundle")
        assert(currentBundlePath != nil, "HBChatKeyBoard.bundle not find")
        self.currentBundle = Bundle(path: currentBundlePath!)
    }
    
    class func path(forFile fullName: String) -> String? {
        return HBBundle.default.currentBundle?.path(forResource: fullName, ofType: nil)
    }
    
    class func bundle() -> Bundle? {
        return HBBundle.default.currentBundle
    }
}

//MARK: ------ 测试数据 -------
extension HBChatKeyBoardView {

    fileprivate func p_clipArrayWithSection() {
        let currentBundle_plistPath = HBBundle.path(forFile: "HBEmojiFile.plist")
        let tempItems = NSArray(contentsOfFile: currentBundle_plistPath ?? "") as! [NSDictionary]
        
        var allItems: [HBEmojiItemsModel] = [HBEmojiItemsModel]()
        for (_, dic) in tempItems.enumerated() {
            var emojiModels = [[HBEmojiItemModel]]()
            let allEmojis = dic["item"] as! [[NSDictionary]]
            for emojis in allEmojis {
                var emojiSection = [HBEmojiItemModel]()
                for emoji in emojis {
                    let emojiModel = HBEmojiItemModel()
                    emojiModel.emojiName = emoji["emojiName"] as! String
                    emojiSection.append(emojiModel)
                }
                emojiModels.append(emojiSection)
            }
            let items = HBEmojiItemsModel()
            items.itemImageName = dic["itemImageName"] as! String
            items.items = emojiModels
            
            let type = dic["itemsType"] as! String
            items.itemsType = type == HBEmojiItemType.emoji.rawValue ? .emoji : .picture
            
            allItems.append(items)
        }
        self.emojiView.allItems = allItems
        
    }
    
    fileprivate func p_loadMoreItem() {
        let cell1 = HBMoreMenuItem()
        cell1.title = "cell1"
        cell1.imageName = "140111"
        cell1.itemAction = {
            print("cell1")
        }
        let cell2 = HBMoreMenuItem()
        cell2.title = "cell2"
        cell2.imageName = "140111"
        cell2.itemAction = {
            print("cell2")
        }
        let cell3 = HBMoreMenuItem()
        cell3.title = "cell3"
        cell3.imageName = "140111"
        cell3.itemAction = {
            print("cell3")
        }
        let cell4 = HBMoreMenuItem()
        cell4.title = "cell4"
        cell4.imageName = "140111"
        cell4.itemAction = {
            print("cell4")
        }
        let cell5 = HBMoreMenuItem()
        cell5.title = "cell5"
        cell5.imageName = "140111"
        cell5.itemAction = {
            print("cell5")
        }
        let cell6 = HBMoreMenuItem()
        cell6.title = "cell6"
        cell6.imageName = "140111"
        cell6.itemAction = {
            print("cell6")
        }
        let cell7 = HBMoreMenuItem()
        cell7.title = "cell7"
        cell7.imageName = "140111"
        cell7.itemAction = {
            print("cell7")
        }
        let cell8 = HBMoreMenuItem()
        cell8.title = "cell8"
        cell8.imageName = "140111"
        cell8.itemAction = {
            print("cell8")
        }
        
        let item_1 = [cell1, cell2, cell3, cell4, cell5, cell6, cell7, cell8]
        
        let cell9 = HBMoreMenuItem()
        cell9.title = "cell9"
        cell9.imageName = "140111"
        cell9.itemAction = {
            print("cell9")
        }
        let cell10 = HBMoreMenuItem()
        cell10.title = "cell10"
        cell10.imageName = "140111"
        cell10.itemAction = {
            print("cell10")
        }
        let cell11 = HBMoreMenuItem()
        cell11.title = "cell11"
        cell11.imageName = "140111"
        cell11.itemAction = {
            print("cell11")
        }
        
        let item_2 = [cell9, cell10, cell11]
        
        self.moreMenuView.allItems = [item_1, item_2]
    }
}

