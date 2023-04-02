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
    
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        //f.timeStyle = .short
        return f
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //loadMessages()
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
