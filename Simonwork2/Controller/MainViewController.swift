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
import GoogleMobileAds

extension UILabel { // 글자 색상 바꾸는 함수
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

extension UIViewController { // 메인 뷰로 이동하는 함수
    func moveToMain(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(identifier: "SecondNavigationController")
        mainViewController.modalPresentationStyle = .fullScreen
        self.show(mainViewController, sender: nil)
    }
}

class MainViewController: UIViewController, GADBannerViewDelegate {
    
    let db = Firestore.firestore()
    let sendUserNotification = SendUserNotification()
    
    @IBOutlet weak var dayCountingLabel: UILabel!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var letterSendButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var settingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let f = DateFormatter()
        let today = Date()
        f.dateStyle = .long
        //f.timeStyle = .short
        
        if let dayCountingLabel = dayCountingLabel,
           let letterSendButton = letterSendButton,
           let settingButton = settingButton,
           let todayDateLabel = todayDateLabel {
            dayCountingLabel.textColor = UIColor(hex: "FDF2DC")
            letterSendButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 20)
            settingButton.setTitle("", for: .normal)
            todayDateLabel.text = f.string(from: today)
        }
        changeLabelColor()
        
        // 배너 광고 설정
        setupBannerViewToBottom()
        
    }
//
//    func addBannerViewToView(_ bannerView: GADBannerView) {
//        bannerView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(bannerView)
//        NSLayoutConstraint.activate([
//            bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
//        ])
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    func changeLabelColor() {
        
        let userDefaultsUid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")
        let userUid = Auth.auth().currentUser?.uid ?? userDefaultsUid
        
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
                            
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let startDateString = dateFormatter.string(from: messagesignupTime)
                            let startDate = dateFormatter.date(from: startDateString)
                            
                            daysCount = Calendar.current.dateComponents([.day], from: startDate!, to: today).day! + 1
                            if let dayCountingLabel = self.dayCountingLabel {
                                dayCountingLabel.text = "\(friendName!)님과\n편지를 주고받은 지 \(daysCount)일째"
                                dayCountingLabel.textColor = .black
                                dayCountingLabel.asColor(targetStringList: [friendName, String(daysCount)], color: .purple)
                            }
                        }
                    }
                }
            }
        }
        sendUserNotification.requestNotificationAuthorization() // 알림 권한 요청 함수
        // if n일 째가 넘어가면 알림 전송하는 함수 추후 구현
        //sendNotification(seconds: 5) // 현재는 3초뒤 테스트 푸시알림. 오늘 편지를 아직 작성하지 않았을때 && 시간이 저녁 11시일때 발송
        
        sendUserNotification.letterSendingPush() // 유저가 오늘 편지를 보냈는지 여부에 따라 notification을 전달하는 함수
        // 오늘 편지를 작성했는지 여부는 userDefaults의 LetterData, updateTime을 확인하면 될 듯
    }
    
    @IBAction func letterSendButtonPressed(_ sender: UIButton) {
        let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WritingViewController") as! WritingViewController
        let navigationController = UINavigationController(rootViewController: nextVC)
        self.show(nextVC, sender: nil)
    }
}


