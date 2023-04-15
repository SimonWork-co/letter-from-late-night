//
//  ReceivedLetterViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/24.
//

import UIKit
import Firebase
import WidgetKit

class ArchiveViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {

    let db = Firestore.firestore()
    var messages: [LetterData] = []
    
    let contentList = LetterDataSource.data // DB 연동
    let cellSpacingHeight: CGFloat = 1
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        //f.timeStyle = .short
        return f
    }()
    
    @IBOutlet weak var tableView: UITableView!
    var updateTimer = Timer()
    var timer : Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = UIColor(hex: "FDF2DC")
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = UIColor(hex: "FDF2DC")
        self.navigationController?.navigationBar.topItem?.titleView?.backgroundColor = UIColor(hex: "FDF2DC")
        
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.black]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        registerXib()
        archiveUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.topItem?.title = "받은 편지함"
        self.navigationController?.navigationBar.topItem?.titleView?.tintColor = .black
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .automatic
    }
    
    private func registerXib() { // 커스텀한 테이블 뷰 셀을 등록하는 함수
        let nibName = UINib(nibName: "CustomizedCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CustomizedCell")
    }
    
    func archiveUpdate() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let components = calendar.dateComponents([.hour, .minute], from: currentDate)
        if let hour = components.hour, let minute = components.minute {
            if hour >= 4 && minute >= 30 {
                // 현재 시간이 오늘 새벽 4시 30분 이후라면 데이터 업데이트 수행
                let yesterdayMidnight = // 자정시간 추출. 현재 4/14일 이라면 4/14일 00시를 추출
                calendar.startOfDay(for: currentDate).timeIntervalSince1970
                loadMessages(time: yesterdayMidnight) // 오늘 자정시간 이전에 작성된 편지를 불러옴
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            } else {
                // 현재 시간이 오늘 새벽 4시 30분 이전이라면 데이터 업데이트 미수행
                let theDayBeforeYesterDay = // 어제의 자정시간 추출. 현재 4/14일 이라면 4/13일 00시를 추출
                calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: currentDate))!.timeIntervalSince1970
                loadMessages(time: theDayBeforeYesterDay) // 어제 자정시간 이전에 작성된 편지를 불러옴
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }
    
    func loadMessages(time: TimeInterval){ // 어제 자정 이전까지 작성된 편지를 불러옴 (오늘 작성된 편지는 불러오지 않음)
        let userFriendCode : String = UserDefaults.shared.object(forKey: "friendCode") as! String
        let userPairFriendCode : String = UserDefaults.shared.object(forKey: "pairFriendCode") as! String
        
        db.collection("LetterData")
            .whereField("sender", isEqualTo: userPairFriendCode)
            .whereField("receiver", isEqualTo: userFriendCode)
            .whereField("updateTime", isLessThan: time)
            .order(by: "updateTime", descending: true)
            .addSnapshotListener { (querySnapshot, error) in
                
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
                                let messageSenderName = data["sender"] as! String
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
                                
                                UserDefaults.shared.set(setTitle, forKey: "latestTitle")
                                UserDefaults.shared.set(setContent, forKey: "latestContent")
                                UserDefaults.shared.set(setUpdateTime, forKey: "latestUpdateDate")
                                UserDefaults.shared.setValue(setLetterColor, forKey: "latestLetterColor")
                                UserDefaults.shared.set(setEmoji, forKey: "latestEmoji")
                                
                                self.dispatchQueue()
                            }
                        }
                    }
                }
            }
    }
    
    func dispatchQueue() {
        DispatchQueue.main.async {
            if self.tableView != nil {
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: false)
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
        return messages.count
    } // section 의 수
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    } // 각 section 간에 간격 부여 (let cellSpacingHeight: CGFloat = 1)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // indexPath에 어떤 cell이 들어갈 것인지 결정하는 메소드 -> cellForRowAt
        // (함수 안에서 UItablenViewCell을 생성하여 커스텀한 다음 그 cell을 반환하면 해당 cell이 특정 행에 적용되어 나타남)
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
        if segue.identifier == "archiveToMessageContent" {
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
        performSegue(withIdentifier: "archiveToMessageContent", sender: indexPath.section)
    }
}
