//
//  ConnectViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/23.
//

import UIKit
import Firebase

class WaitingViewController: UIViewController {
    
    var inputPairFriendCode : String?
    var documentID : String?
    var timer = Timer()
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var helloLabel: UILabel!
    
    let userName = UserDefaults.standard.string(forKey: "userName")!
    let myFriendCode = UserDefaults.standard.string(forKey: "friendCode")!
    let uid = UserDefaults.standard.string(forKey: "ALetterFromLateNightUid")!
    let documentId = UserDefaults.standard.string(forKey: "documentID")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        helloLabel.text = "안녕하세요! \(userName)님"
        helloLabel.asColor(targetStringList: [userName], color: .black)
        //self.navigationController?.isNavigationBarHidden = true
        
        timer.invalidate()
        let timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(inputFriendCodeCheck), userInfo: nil, repeats: false)
        // inputFriendCode를 friendCode로 가지고 있는 유저의 문서를 실시간 조회 -> 실시간으로 조회하는 중에 유저가 pairFriendCode에다가 나의 friendCode를 넣으면 mainVC로 세그
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController의 view가 load됨")
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc func fire() {
        print("fire!!")
    }
    
    @objc func inputFriendCodeCheck() {
        //inputFriendCode가 상대방의 friendCode와 일치하는지 실시간으로 조회 (상대방이 나의 친구코드를 connectTyping VC에서 입력하게 되면 dbDocumentsCall()를 실행
        
        db.collection("UserData").document(documentId) // 상대방의 uid 가 document의 이름임
            .addSnapshotListener { (documentSnapshot, error) in
                
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                print("Current data: \(data)")
                
                if data["pairFriendCode"] as? String == self.myFriendCode { // 상대방이 pairFriendCode로 나의 friendCode를 업데이트하면, startVC로 세그
                    print("pairFriendCode 연동 완료")
                    // waitingVC 화면으로 보내기
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let StartViewController = storyboard.instantiateViewController(identifier: "StartViewController")
                    StartViewController.modalPresentationStyle = .fullScreen
                    self.navigationController?.show(StartViewController, sender: nil)
                }
            }
        return
    }
}
