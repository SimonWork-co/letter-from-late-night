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
        // Do any additional setup after loading the view.
        //loadMessages()
        
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
    //    func loadMessages(){
    //
    //        db.collection("LetterData")
    //            .order(by: "updateTime")
    //            .addSnapshotListener { (querySnapshot, error) in
    //
    //                self.messages = []
    //
    //                if let e = error {
    //                    print("There was an issue retrieving data from Firestore. \(e)")
    //                } else {
    //                    if let snapshotDocuments = querySnapshot?.documents {
    //                        for doc in snapshotDocuments {
    //                            let data = doc.data()
    //                            if let messageTitle = data["title"] as? String,
    //                               let messageContent = data["content"] as? String {
    //
    //                                let message_UpdateTime = data["updateTime"] as? Timestamp
    //                                let messageUpdateTime = message_UpdateTime!.dateValue()
    //
    //                                let messageList = LetterData(title: messageTitle, content: messageContent, updateTime: messageUpdateTime)
    //                                self.messages.append(messageList)
    //
    //                            }
    //                        }
    //                    }
    //                }
    //            }
    //    }
    
}
