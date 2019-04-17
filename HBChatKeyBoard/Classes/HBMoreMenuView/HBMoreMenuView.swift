//
//  HBMoreMenuView.swift
//  HBChatKeyBoard_Example
//
//  Created by 伍宏彬 on 2019/3/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

fileprivate let kHBMoreMenuViewHeight: CGFloat = 195
fileprivate let kHBMoreMenuViewPageControlHeight: CGFloat = 20
fileprivate let kHBMoreMenuViewEdgePadding: CGFloat = 15
fileprivate let kHBMoreMenuViewItemSize: CGSize = CGSize(width: 55, height: 65)

fileprivate let kHBMoreMenuViewRowPadding: CGFloat = (kHBMoreMenuViewHeight - kHBMoreMenuViewPageControlHeight - 2 * kHBMoreMenuViewItemSize.height - 2 * kHBMoreMenuViewEdgePadding)/(2 - 1)
fileprivate let kHBMoreMenuViewColomPadding: CGFloat = (UIScreen.main.bounds.size.width - 4 * kHBMoreMenuViewItemSize.width - 2 * kHBMoreMenuViewEdgePadding - 2 * 0.001)/(4 - 1)

public class HBMoreMenuItem: NSObject {
    public var title: String = ""
    public var imageName: String = ""
    public var isPlaceHold: Bool = false
    public var itemAction: (() -> ())?
}

public class HBMoreMenuView: UIView {
    
    /// 数组中最多8个Item，排列固定是2x4的布局
    public var allItems: [[HBMoreMenuItem]] = [[HBMoreMenuItem]]() {
        didSet {
            self.menuCollectionView.reloadData()
            self.menuCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
            reloadPage(IndexPath(item: 0, section: 0))
        }
    }
    
    fileprivate lazy var menuCollectionView: UICollectionView = {
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
    
    fileprivate lazy var pageControl: UIPageControl = {
        let tl = UIPageControl(frame: CGRect.zero)
        tl.pageIndicatorTintColor = UIColor.lightGray
        tl.currentPageIndicatorTintColor = UIColor.black
        tl.backgroundColor = self.menuCollectionView.backgroundColor
        return tl
    }()
    
    public class func menuView() -> HBMoreMenuView {
        var safeBottom: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeBottom = UIWindow().safeAreaInsets.bottom
        }
        return HBMoreMenuView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: kHBMoreMenuViewHeight + safeBottom))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.menuCollectionView.register(HBMoreCollectionCell.self, forCellWithReuseIdentifier: HBMoreCollectionCell.self.description())
        self.addSubview(self.menuCollectionView)
        self.addSubview(self.pageControl)
        
        self.menuCollectionView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(kHBMoreMenuViewHeight - kHBMoreMenuViewPageControlHeight)
        }
        self.pageControl.snp.makeConstraints { (make) in
            make.top.equalTo(self.menuCollectionView.snp.bottom)
            make.height.equalTo(kHBMoreMenuViewPageControlHeight)
            make.left.right.equalToSuperview()
        }
        
    }
    
    fileprivate func reloadPage(_ indexPath: IndexPath) {
        //        print("section: \(indexPath.section) - item: \(indexPath.item)")
        self.pageControl.numberOfPages = self.allItems.count
        self.pageControl.currentPage = indexPath.item
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension HBMoreMenuView: UICollectionViewDelegate, UICollectionViewDataSource {
    private func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexPath = self.menuCollectionView.indexPathForItem(at: CGPoint(x: scrollView.contentOffset.x, y: 0))!
        reloadPage(indexPath)
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allItems.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HBMoreCollectionCell.self.description(), for: indexPath) as! HBMoreCollectionCell
        cell.menus = self.allItems[indexPath.item]
        return cell
    }
}

extension HBMoreMenuView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: collectionView.frame.size.height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.001
    }
}

class HBMoreCollectionCell: UICollectionViewCell {
    
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
    
    var menus: [HBMoreMenuItem] = [HBMoreMenuItem]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.collectionView.register(HBMenuCell.self, forCellWithReuseIdentifier: HBMenuCell.self.description())
        self.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HBMoreCollectionCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.menus.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HBMenuCell.self.description(), for: indexPath) as! HBMenuCell
        let dic = self.menus[indexPath.item]
        cell.iconImageView.image = UIImage.hb_imageName(name: dic.imageName)
        cell.titleLable.text = dic.title
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.menus[indexPath.item].itemAction?()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return kHBMoreMenuViewRowPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return kHBMoreMenuViewColomPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: kHBMoreMenuViewEdgePadding, left: kHBMoreMenuViewEdgePadding, bottom: kHBMoreMenuViewEdgePadding, right: kHBMoreMenuViewEdgePadding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return kHBMoreMenuViewItemSize
    }
}

class HBMenuCell: UICollectionViewCell {
    
    fileprivate lazy var iconImageView: UIImageView = {
        let tl = UIImageView()
        tl.contentMode = .scaleAspectFit
        return tl
    }()
    
    fileprivate lazy var titleLable: UILabel = {
        let tl = UILabel()
        tl.textColor = UIColor.lightGray
        tl.textAlignment = .center
        return tl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.titleLable)
        self.addSubview(self.iconImageView)
        self.titleLable.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(15)
        }
        self.iconImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.titleLable.snp.top).offset(-5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
