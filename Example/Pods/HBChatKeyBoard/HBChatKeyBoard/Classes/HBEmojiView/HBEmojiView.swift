//
//  HBEmojiView.swift
//  HBChatKeyBoard_Example
//
//  Created by 伍宏彬 on 2019/3/5.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

fileprivate let kHBEmojiViewSendButtonHeight: CGFloat = 35
fileprivate let kHBEmojiViewItemEdgePadding: CGFloat = 20
fileprivate let kHBEmojiViewItemEmojiViewHeight: CGFloat = 195
fileprivate let kHBEmojiViewItemSectionLeftRightPadding: CGFloat = 0.001

/// 目前仅支持两种排列方式（行 x 列）
///
/// - emoji: 3 x 8
/// - picture: 2 x 4
public enum HBEmojiItemType: String {//
    case emoji = "emoji"
    case picture = "picture"
    case delete = "delete"
    case clear = "clear"
}

public class HBEmojiItemsModel: NSObject {
    public var itemImageName: String = ""
    public var itemsType: HBEmojiItemType = .emoji {
        didSet {
            self.itemSize = itemsType == .emoji ? CGSize(width: 25, height: 25) : CGSize(width: 55, height: 55)
            self.itemColomCount = itemsType == .emoji ? 8 : 4
            self.itemRowCount = itemsType == .emoji ? 3 : 2
            
            self.itemColomPadding = (UIScreen.main.bounds.size.width - 2 * kHBEmojiViewItemSectionLeftRightPadding - self.itemColomCount * self.itemSize.width - 2 * kHBEmojiViewItemEdgePadding)/(self.itemColomCount - 1)
            self.itemRowPadding = (kHBEmojiViewItemEmojiViewHeight - self.itemRowCount * self.itemSize.height - 2 * kHBEmojiViewItemEdgePadding - kHBEmojiViewSendButtonHeight)/(self.itemRowCount - 1)
        }
    }
    public var items: [[HBEmojiItemModel]] = [[HBEmojiItemModel]]()
    
    fileprivate var isSelect: Bool = false
    fileprivate var itemColomPadding: CGFloat = 0
    fileprivate var itemRowPadding: CGFloat = 0
    fileprivate var itemColomCount: CGFloat = 0
    fileprivate var itemRowCount: CGFloat = 0
    fileprivate var itemSize: CGSize = CGSize.zero
}

public class HBEmojiItemModel: NSObject {
    public var emojiName: String = ""
}

//TODO: @whb 1. 支持网络图片 
public class HBEmojiView: UIView {
    public var selectEmoji: ((_ emojiAttachment: HBTextAttachment) -> Void)?
    public var selectPicture: ((_ pictureModel: HBEmojiItemModel) -> Void)?
    public var deleteAction: (() -> ())?
    public var sendAction: (() -> ())?
    public var clearAction: (() -> ())?
    
    public var allItems: [HBEmojiItemsModel] = [HBEmojiItemsModel]() {
        didSet {
            guard self.allItems.count > 0 else { return }
            self.allItems.first?.isSelect = true
            self.collectionView(self.itemCollectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        }
    }
    
    fileprivate lazy var emojisCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let tl = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        tl.delegate = self
        tl.dataSource = self
        tl.isPagingEnabled = true
        tl.backgroundColor = UIColor.white
        tl.showsHorizontalScrollIndicator = false
        tl.showsVerticalScrollIndicator = false
        tl.alwaysBounceHorizontal = true
        return tl
    }()
    
    fileprivate lazy var itemCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let tl = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        tl.alwaysBounceHorizontal = true
        tl.delegate = self
        tl.dataSource = self
        tl.backgroundColor = UIColor.white
        tl.showsHorizontalScrollIndicator = false
        tl.showsVerticalScrollIndicator = false
        return tl
    }()
    
    fileprivate lazy var sendButton: UIButton = {
        let tl = UIButton(type: UIButtonType.custom)
        tl.setTitle("发送", for: UIControlState.normal)
        tl.backgroundColor = UIColor.black
        tl.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        tl.addTarget(self, action: #selector(HBEmojiView.sendAction(_:)), for: .touchUpInside)
        return tl
    }()
    fileprivate lazy var pageControl: UIPageControl = {
        let tl = UIPageControl(frame: CGRect.zero)
        tl.pageIndicatorTintColor = UIColor.lightGray
        tl.currentPageIndicatorTintColor = UIColor.black
        return tl
    }()
    
    public class func emojiView() -> HBEmojiView {
        var safeBottom: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeBottom = UIWindow().safeAreaInsets.bottom
        }
        return HBEmojiView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: kHBEmojiViewItemEmojiViewHeight + safeBottom))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray
        self.itemCollectionView.register(HBBottomItemCell.self, forCellWithReuseIdentifier: HBBottomItemCell.self.description())
        self.emojisCollectionView.register(HBEmojiCollectionCell.self, forCellWithReuseIdentifier: HBEmojiCollectionCell.self.description())
        self.addSubview(self.emojisCollectionView)
        self.addSubview(self.sendButton)
        self.addSubview(self.itemCollectionView)
        self.addSubview(self.pageControl)
        self.emojisCollectionView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(160)
        }
        self.sendButton.snp.makeConstraints { (make) in
            make.height.equalTo(kHBEmojiViewSendButtonHeight)
            make.width.equalTo(55)
            make.top.equalTo(self.emojisCollectionView.snp.bottom)
            make.right.equalToSuperview()
        }
        self.itemCollectionView.snp.makeConstraints { (make) in
            make.height.equalTo(self.sendButton)
            make.left.equalToSuperview()
            make.right.equalTo(self.sendButton.snp.left)
            make.centerY.equalTo(self.sendButton.snp.centerY)
        }
        self.pageControl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.sendButton.snp.top)
            make.height.equalTo(15)
            make.width.equalToSuperview()
        }
    }

    fileprivate func reloadPage(_ indexPath: IndexPath) {
//        print("section: \(indexPath.section) - item: \(indexPath.item)")
        self.pageControl.numberOfPages = self.allItems[indexPath.section].items.count
        self.pageControl.currentPage = indexPath.item
        
        self.sendButton.snp.updateConstraints { (make) in
            if self.allItems[indexPath.section].itemsType == .picture {
                make.width.equalTo(0)
            } else {
                make.width.equalTo(55)
            }
        }
        
        let lastSelectModel = self.allItems.filter { (item) -> Bool in
            item.isSelect == true
        }.first
        if lastSelectModel != nil {
            lastSelectModel!.isSelect = false
        }
        self.allItems[indexPath.section].isSelect = true
        self.itemCollectionView.scrollToItem(at: IndexPath(item: indexPath.section, section: 0), at: .centeredHorizontally, animated: true)
        self.itemCollectionView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
//MARK: Action
extension HBEmojiView {
    @objc fileprivate func sendAction(_ btn: UIButton) {
        self.sendAction?()
    }
}

extension HBEmojiView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.emojisCollectionView else {
            return
        }
        let indexPath = self.emojisCollectionView.indexPathForItem(at: CGPoint(x: max(scrollView.contentOffset.x, 0), y: 0))
        guard indexPath != nil else { return }
        reloadPage(indexPath!)
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.emojisCollectionView {
            return self.allItems.count
        }
        return 1
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.emojisCollectionView {
            return self.allItems[section].items.count
        }
        return self.allItems.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.emojisCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HBEmojiCollectionCell.self.description(), for: indexPath) as! HBEmojiCollectionCell
            cell.emojisType = self.allItems[indexPath.section].itemsType
            cell.colomPadding = self.allItems[indexPath.section].itemColomPadding
            cell.rowPadding = self.allItems[indexPath.section].itemRowPadding
            cell.itemSize = self.allItems[indexPath.section].itemSize
            cell.emojis = self.allItems[indexPath.section].items[indexPath.item]
            cell.actionBlock = { (type, model) in
                switch type {
                case .emoji:
                    let textAtt = HBTextAttachment.createAttachment()
                    textAtt.emojiName = model.emojiName
                    textAtt.image = UIImage.hb_imageName(name: textAtt.emojiName)
                    self.selectEmoji?(textAtt)
//                    print("emoji")
                case .picture:
                    self.selectPicture?(model)
//                    print("picture")
                case .delete:
                    self.deleteAction?()
                case .clear:
                    self.clearAction?()
                }
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HBBottomItemCell.self.description(), for: indexPath) as! HBBottomItemCell
        let dic = self.allItems[indexPath.item]
        cell.iconImageView.image = UIImage.hb_imageName(name: dic.itemImageName)
        cell.isSelected = dic.isSelect
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == self.itemCollectionView else {
            return
        }
        let selectIndexPath = IndexPath(item: 0, section: indexPath.item)
        self.emojisCollectionView.scrollToItem(at: selectIndexPath, at: .centeredHorizontally, animated: false)
        reloadPage(selectIndexPath)
    
    }
}

extension HBEmojiView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.emojisCollectionView {
            return CGSize(width: UIScreen.main.bounds.size.width, height: collectionView.frame.size.height)
        }
        return CGSize(width: kHBEmojiViewSendButtonHeight * 2, height: kHBEmojiViewSendButtonHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return kHBEmojiViewItemSectionLeftRightPadding
    }
}

class HBBottomItemCell: UICollectionViewCell {
    lazy var iconImageView: UIImageView = {
        let tl = UIImageView()
        tl.contentMode = .scaleAspectFit
        return tl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let normalView = UIView()
        normalView.backgroundColor = UIColor.white
        self.backgroundView = normalView
        
        let selectView = UIView()
        selectView.backgroundColor = UIColor.lightGray
        self.selectedBackgroundView = selectView
        
        self.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HBEmojiCollectionCell: UICollectionViewCell {
    
    var actionBlock: ((_ itemType: HBEmojiItemType, _ itemModel: HBEmojiItemModel) -> ())?
    
    fileprivate lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let tl = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        tl.alwaysBounceHorizontal = true
        tl.delegate = self
        tl.dataSource = self
        tl.backgroundColor = UIColor.white
        tl.showsHorizontalScrollIndicator = false
        tl.showsVerticalScrollIndicator = false
        tl.isScrollEnabled = false
        return tl
    }()
    
    var emojis: [HBEmojiItemModel] = [HBEmojiItemModel]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var emojisType: HBEmojiItemType = .emoji
    var colomPadding: CGFloat = 0
    var rowPadding: CGFloat = 0
    var itemSize: CGSize = CGSize.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.collectionView.register(HBEmojiCell.self, forCellWithReuseIdentifier: HBEmojiCell.self.description())
        self.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HBEmojiCollectionCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HBEmojiCell.self.description(), for: indexPath) as! HBEmojiCell
        cell.iconImageView.image = UIImage.hb_imageName(name: self.emojis[indexPath.item].emojiName)
        cell.indexPath = indexPath
        cell.clearAll = { (selectIndexPath) in
            guard self.emojis[indexPath.item].emojiName == "delete" else { return }
            self.actionBlock?(.clear, self.emojis[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.emojis[indexPath.item].emojiName != "" else {
            print("占位图点击")
            return
        }
        guard self.emojis[indexPath.item].emojiName != "delete" else {
            self.actionBlock?(.delete, self.emojis[indexPath.item])
            return
        }
        self.actionBlock?(self.emojisType, self.emojis[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.rowPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.colomPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: kHBEmojiViewItemEdgePadding, left: kHBEmojiViewItemEdgePadding, bottom: kHBEmojiViewItemEdgePadding, right: kHBEmojiViewItemEdgePadding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }
}

class HBEmojiCell: UICollectionViewCell {
    var indexPath: IndexPath = IndexPath()
    var clearAll: ((_ indexPath: IndexPath) -> ())?
    
    lazy var iconImageView: UIImageView = {
        let tl = UIImageView()
        tl.isUserInteractionEnabled = true
        tl.contentMode = .scaleAspectFit
        return tl
    }()
    
    fileprivate lazy var longPress: UILongPressGestureRecognizer = {
        let tl = UILongPressGestureRecognizer(target: self, action: #selector(HBEmojiCell.longPressAction))
        return tl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
        self.iconImageView.addGestureRecognizer(longPress)
    }
    
    @objc fileprivate func longPressAction() {
        guard self.longPress.state == .began else {
            return
        }
        self.clearAll?(self.indexPath)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
