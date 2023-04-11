//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Firebase
import EmojiPicker

class LetterViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var titleTextView: UITextView!
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleTextView.text = receivedTitleText
        contentTextView.text = receivedContentText
        dateLabel.text = formatter.string(from: receivedUpdateDate ?? Date())
        letterBg.backgroundColor = UIColor(hex: receivedLetterColor!)
        emojiLabel.text = receivedEmoji!
        
        print("titleTextView.text : \(titleTextView.text)")
        print("contentTextView.text : \(contentTextView.text)")
        print("dateLabel.text : \(dateLabel.text)")
        print("letterBg.backgroundColor: \(letterBg.backgroundColor)")
        print("emojiLabel.text: \(emojiLabel.text)")
        
    }
    
}
