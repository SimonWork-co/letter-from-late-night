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

class MainViewController: UIViewController {
    
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var dayCountingLabel: UILabel!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var letterSendButton: UIButton!
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        let firebaseAuth = Auth.auth()
        
        do {
          try firebaseAuth.signOut()
            print("로그아웃 성공")
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
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

