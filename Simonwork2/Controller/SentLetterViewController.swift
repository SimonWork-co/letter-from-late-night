//
//  ReceivedLetterViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/24.
//

import UIKit
import Firebase
import WidgetKit
import GoogleMobileAds

class SentLetterViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let db = Firestore.firestore()
    var messages: [LetterData] = []
    let refreshControl = UIRefreshControl()
    
    //let contentList = LetterDataSource.data // DB 연동
    let cellSpacingHeight: CGFloat = 1
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        //f.timeStyle = .short
        return f
    }()
    
    @IBOutlet weak var letterTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = UIColor(hex: "FDF2DC")
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = UIColor(hex: "FDF2DC")
        self.navigationController?.navigationBar.topItem?.titleView?.backgroundColor = UIColor(hex: "FDF2DC")
        
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.black]
        self.view.snapshotView(afterScreenUpdates: true)
        
        letterTableView.delegate = self
        letterTableView.dataSource = self
        
        registerXib()
        loadMessages()
        
        // 배너 광고 설정
        setupBannerViewToBottom(adUnitID: Constants.GoogleAds.normalBanner)
        
        // Add refresh control to table view
        if #available(iOS 10.0, *) {
            letterTableView.refreshControl = refreshControl
        } else {
            letterTableView.addSubview(refreshControl)
        }
        // Add target action for refresh control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    // Function to handle refresh action
    @objc func refreshData(_ sender: Any) {
        loadMessages()
        refreshControl.endRefreshing()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.topItem?.title = "보낸 편지함"
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.largeTitleDisplayMode = .automatic
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func registerXib() { // 커스텀한 테이블 뷰 셀을 등록하는 함수
        let nibName = UINib(nibName: "CustomizedCell", bundle: nil)
        letterTableView.register(nibName, forCellReuseIdentifier: "CustomizedCell")
    }
    
    func loadMessages(){
        
        let userFriendCode : String = UserDefaults.shared.object(forKey: "friendCode") as! String
        let userPairFriendCode : String = UserDefaults.shared.object(forKey: "pairFriendCode") as! String
        
        print("userFriendCode: \(userFriendCode)")
        print("userPairFriendCode: \(userPairFriendCode)")
        
        db.collection("LetterData")
            .whereField("sender", isEqualTo: userFriendCode)
            .whereField("receiver", isEqualTo: userPairFriendCode)
            .order(by: "updateTime", descending: true)
            .addSnapshotListener { (querySnapshot, error) in
                
                self.messages = []
                
                if let e = error {
                    print("There was an issue retrieving data from Firestore. \(e)")
                } else {
                    if let snapshotDocuments = querySnapshot?.documents {
                        for doc in snapshotDocuments {
                            let data = doc.data()
                            if let messageTitle = data["title"] as? String,
                               let message_UpdateTime = data["updateTime"] as? Timestamp {
                                
                                let messageUpdateTime = message_UpdateTime.dateValue()
                                let messageContent = data["content"] as! String
                                let messageFriendCode = data["sender"] as! String
                                let messageSenderName = data["senderName"] as! String
                                let messagePairFriendCode = data["receiver"] as! String
                                let messageLetterColor = data["letterColor"] as! String
                                let messageEmoji = data["emoji"] as! String
                                
                                let messageList = LetterData(
                                    sender: messageFriendCode,
                                    senderName: messageSenderName,
                                    receiver: messagePairFriendCode,
                                    title: messageTitle,
                                    content: messageContent,
                                    updateTime: messageUpdateTime,
                                    letterColor: messageLetterColor,
                                    emoji: messageEmoji
                                )
                                self.messages.append(messageList)
                                
                                let setTitle = self.messages[0].title
                                let setContent = self.messages[0].content
                                let setUpdateTime = self.messages[0].updateTime
                                let setLetterColor = self.messages[0].letterColor
                                let setEmoji = self.messages[0].emoji
                                let setSenderName = self.messages[0].senderName
                                
                                self.dispatchQueue()
                            }
                        }
                    }
                }
            }
    }
    
    func dispatchQueue() {
        DispatchQueue.main.async {
            if self.letterTableView != nil {
                self.letterTableView.reloadData()
                self.letterTableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: false)
                print("dispatchQueue 완료!")
            } else {
                print("self.letterTableView에 nil 출력")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    } // section 당 row의 수
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let placeholderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        placeholderLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
        placeholderLabel.text = "아직 보낸 편지가 없어요"
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
        
        if messages.count == 0 {
            tableView.backgroundView = placeholderLabel
        } else {
            tableView.backgroundView = nil
        }
        return messages.count
    } // section 의 수
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    } // 각 section 간에 간격 부여 (let cellSpacingHeight: CGFloat = 1)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // indexPath에 어떤 cell이 들어갈 것인지 결정하는 메소드 -> cellForRowAt
        // (함수 안에서 UItableViewCell을 생성하여 커스텀한 다음 그 cell을 반환하면 해당 cell이 특정 행에 적용되어 나타남)
        let message = messages[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomizedCell", for: indexPath) as! CustomizedCell
        
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.letterTitleLable?.text = message.title
        cell.letterDateLabel?.text = formatter.string(from: message.updateTime)
        cell.backgroundColor = UIColor(hex: message.letterColor)
        cell.emojiLabel.text = message.emoji
        
        navigationController?.navigationBar.sizeToFit()
        
        return cell
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sentLetterToMessageContent" {
            let nextVC = segue.destination as? LetterViewController
            
            if let index = sender as? Int {
                nextVC?.receivedTitleText = messages[index].title
                nextVC?.receivedContentText = messages[index].content
                nextVC?.receivedUpdateDate = messages[index].updateTime
                nextVC?.receivedLetterColor = messages[index].letterColor
                nextVC?.receivedEmoji = messages[index].emoji
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // cell 클릭 시, cell 내용을 보여주는 view controller로 이동
        performSegue(withIdentifier: "sentLetterToMessageContent", sender: indexPath.section)
    }
}


