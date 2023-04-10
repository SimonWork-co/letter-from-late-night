//
//  ViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/08.
//

import UIKit
import Firebase
import GoogleSignIn
import UserNotifications

extension UILabel {
    func asColor(targetStringList: [String?], color: UIColor) {
        let fullText = text ?? ""
        let attributedString = NSMutableAttributedString(string: fullText)
        
        targetStringList.forEach{
            let range = (fullText as NSString).range(of: $0 ?? "")
            attributedString.addAttributes([.foregroundColor: color as Any], range: range)
        }
        attributedText = attributedString
    }
}

extension UIViewController {
    func moveToMain(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(identifier: "TabBarController")
        mainViewController.modalPresentationStyle = .fullScreen
        self.show(mainViewController, sender: nil)
    }
}

class MainViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var dayCountingLabel: UILabel!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var letterSendButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeLabelColor()
        
        let f = DateFormatter()
        let today = Date()
        f.dateStyle = .long
        //f.timeStyle = .short
        todayDateLabel.text = f.string(from: today)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    func changeLabelColor() {
        
        let userUid = Auth.auth().currentUser?.uid
        let userName : String = UserDefaults.shared.object(forKey: "userName") as! String
        
        db.collection("UserData").whereField("uid", isEqualTo: userUid).getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error: \(error)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let message_signupTime = data["signupTime"] as? Timestamp, let messagePairFriendCode = data["pairFriendCode"] as? String {
                            
                            let friendName = data["friendName"] as? String
                            let calendar = Calendar.current
                            let today = Date()
                            let dateFormatter = DateFormatter()
                            var daysCount : Int = 0
                    
                            let messagesignupTime = message_signupTime.dateValue() // dateValue() : 날짜는 정확하지만 시간 단위는 부정확할 수 있음.
                            //print("messagesignupTime: \(messagesignupTime)")
                            //print("messagePairFriendCode: \(messagePairFriendCode)")
                            
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let startDateString = dateFormatter.string(from: messagesignupTime)
                            let startDate = dateFormatter.date(from: startDateString)

                            daysCount = Calendar.current.dateComponents([.day], from: startDate!, to: today).day! + 1
                            
                            self.dayCountingLabel.text = "\(friendName!)님과\n편지를 주고받은 지 \(daysCount)일째"
                            self.dayCountingLabel.asColor(targetStringList: [friendName, String(daysCount)], color: .purple)
                        }
                    }
                }
            }
        }
        requestNotificationAuthorization() // 알림 권한 요청 함수
        // if n일 째가 넘어가면 알림 전송하는 함수 추후 구현
        sendNotification(seconds: 3) // 현재는 3초뒤 테스트 푸시알림. 오늘 편지를 아직 작성하지 않았을떼 && 시간이 저녁 11시일때 발송
    }
    
    func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .sound)
        userNotificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    func sendNotification(seconds: Double) {
        let notiContent = UNMutableNotificationContent() // 푸시알림 컨텐츠 넣는 클래스

        notiContent.title = "밤편지"
        notiContent.body = "답장을 기다리고 있는 상대방에게 밤편지를 전해주세요."
        
        let TimeIntervalTrigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "intervalTimerDone",
                                            content: notiContent,
                                            trigger: TimeIntervalTrigger)
        
        // 알림센터에 추가
        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
    
    @IBAction func letterSendButtonPressed(_ sender: UIButton) {
        let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WritingViewController") as! WritingViewController
        let navigationController = UINavigationController(rootViewController: nextVC)
        self.show(nextVC, sender: nil)
    }
}


