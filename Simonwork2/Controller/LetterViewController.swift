//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Firebase
import EmojiPicker
import GoogleMobileAds

extension UITextView {
    func alignTextVerticallyInContainer() {
        var topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect;
        self.contentInset.top = topCorrect
    }
}

class LetterViewController: UIViewController {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var letterBg: UIView!
    @IBOutlet weak var emojiLabel: UILabel!
    
    let db = Firestore.firestore()
    
    var receivedTitleText: String?
    var receivedContentText: String?
    var receivedUpdateDate: Date?
    var receivedLetterColor : String?
    var receivedEmoji : String?
    
    // Create right UIBarButtonItem.
    lazy var rightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "수정", style: .plain, target: self, action: #selector(editButtonPressed))
        button.tag = 2
        
        return button
    }()

// Button event.
    @objc private func editButtonPressed(_ sender: Any) {
        if let button = sender as? UIBarButtonItem {
            switch button.tag {
            case 2:
                // Change the background color to red.
                self.view.backgroundColor = .red
                // 12시 이전에 수정 버튼 클릭 시 메시지가 수정되는 기능 구현 필요
            default:
                print("error")
            }
        }
    }
    
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        //f.timeStyle = .short
        return f
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.text = ""
        contentTextView?.text = ""
        
        self.contentTextView.alignTextVerticallyInContainer()
        // 배너 광고 설정
        setupBannerViewToBottom(adUnitID: Constants.GoogleAds.normalBanner)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel?.font = UIFont(name: "NanumMyeongjoBold", size: 20)
        contentTextView?.font = UIFont(name: "NanumMyeongjo", size: 17)
        
        titleLabel?.text = receivedTitleText
        contentTextView?.text = receivedContentText
        
        dateLabel?.text = formatter.string(from: receivedUpdateDate ?? Date())
        letterBg?.backgroundColor = UIColor(hex: receivedLetterColor!)
        
        //setupEmoji()
        emojiLabel?.text = receivedEmoji!

    }
}
