//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Firebase

class LetterViewController: UIViewController {
    
    let db = Firestore.firestore()
    var messages: [LetterData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //loadMessages()
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
//                               let message_UpdateTime = data["updateTime"] as? Timestamp {
//                                let messageUpdateTime = message_UpdateTime.dateValue()
//                                let messageList = LetterData(title: messageTitle, updateTime: messageUpdateTime)
//                                self.messages.append(messageList)
//
//                                DispatchQueue.main.async {
//                                    self.tableView.reloadData()
//                                    let indexPath = IndexPath(row: 0, section: self.messages.count - 1)
//                                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//    }

}
