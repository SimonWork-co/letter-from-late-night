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


class MainViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var dayCountingLabel: UILabel!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var letterSendButton: UIButton!
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationController?.isNavigationBarHidden = true
        //dayCountingLabel.text = ""
        changeLabelColor()
        
        let f = DateFormatter()
        f.dateStyle = .long
        //f.timeStyle = .short
        
        todayDateLabel.text = f.string(from: Date())
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController의 view가 load됨")
        //navigationItem.hidesBackButton = true
        navigationController?.isNavigationBarHidden = true
        self.navigationBar.hidesBackButton = true
    }
    
    func changeLabelColor() {
        //todayDateLabel.text = formatter.string(from: Date()) // 현재 시간을 표현
        
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
                            
                            self.dayCountingLabel.text = "\(userName)님과 편지를\n주고받은 지 \(daysCount)일째"
                            self.dayCountingLabel.asColor(targetStringList: [userName, String(daysCount)], color: .purple)
                        }
                    }
                }
            }
        }
        requestNotificationAuthorization() // 알림 권한 요청 함수
        
        // if n일 째가 넘어가면 알림 전송하는 함수 추후 구현
        sendNotification(seconds: 3) // 현재는 3초뒤 테스트 푸시알림
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
    
    @IBAction func profileButton(_ sender: UIBarButtonItem) {
        //GIDSignIn.sharedInstance.signOut()
        print("worked!")
        navigationController?.popToRootViewController(animated: true)
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("로그아웃 성공")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func settingButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "mainToSetting", sender: self)
    }
    
}


