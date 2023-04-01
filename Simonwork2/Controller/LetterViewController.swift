//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Firebase

class LetterViewController: UIViewController {
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    
    let db = Firestore.firestore()
    
    var receivedTitleText: String?
    var receivedContentText: String?
    var receivedUpdateDate: Date?
    
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
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
        
        print(titleTextView.text)
        print(contentTextView.text)
        print(dateLabel.text)
        
        
    }
    
}
