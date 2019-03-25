//
//  ViewController.swift
//  HBChatKeyBoard
//
//  Created by 601479318@qq.com on 02/28/2019.
//  Copyright (c) 2019 601479318@qq.com. All rights reserved.
//

import UIKit
import HBChatKeyBoard

class ViewController: UIViewController {
    let chatView = HBChatKeyBoardView.keyBoardView()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        chatView.backgroundColor = UIColor.gray
        chatView.keyBoardViewHeightChange = { [weak self] (height) in
            guard let `self` = self else { return }
            self.chatView.snp.updateConstraints { (make) in
                make.height.equalTo(height)
            }
        }
        chatView.sendTextBlock = { (text) in
            print(text)
        }
        self.view.addSubview(chatView)
        chatView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(chatView.frame.size.height)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil) { (info) in
            let boardVaule = info.userInfo!["UIKeyboardFrameEndUserInfoKey"] as! NSValue
            let boardY = boardVaule.cgRectValue.size.height
            self.chatView.snp.updateConstraints({ (make) in
                if #available(iOS 11.0, *) {
                    make.bottom.equalTo(-boardY + self.view.safeAreaInsets.bottom)
                } else {
                    make.bottom.equalTo(-boardY)
                }
            })
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
            
            
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil) { (info) in
            self.chatView.snp.updateConstraints({ (make) in
                make.bottom.equalTo(0)
            })
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

