//
//  SettingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/24.
//

import UIKit
import Firebase
import GoogleSignIn
import GoogleMobileAds

extension UIViewController {
    func alert(title: String, message: String, actiondTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actiondTitle, style: .default)
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
}

class SettingViewController: UIViewController {
    
    @IBOutlet weak var nicknameChangeTextField: UITextField!
    @IBOutlet weak var nicknameChangeButton: UIButton!
    
    @IBOutlet weak var nicknameChangeLabel: UILabel!
    @IBOutlet weak var manualButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    
    let signupVC = SignupViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 배너 광고 설정
        setupBannerViewToBottom()
        
        if let nicknameChangeLabel = nicknameChangeLabel,
            let nicknameChangeButton = nicknameChangeButton,
            let manualButton = manualButton,
            let disconnectButton = disconnectButton,
            let logoutButton = logoutButton,
            let helpButton = helpButton,
            let quitButton = quitButton {
            nicknameChangeLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 15)
            nicknameChangeButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 17)
            manualButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
            disconnectButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
            logoutButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
            helpButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
            quitButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
        }
    }
    
    @IBAction func changeNicknameButtonPressed(_ sender: UIButton) {
        
        // 닉네임 변경 수정 버튼 클릭 시
        let userName = UserDefaults.shared.string(forKey: "userName") ?? ""
        let userUid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid") ?? ""
        let userPairFriendCode = UserDefaults.shared.string(forKey: "pairFriendCode") ?? ""
        
        let inputNewNickname = nicknameChangeTextField.text
        if inputNewNickname != nil {
            
            let sheet = UIAlertController(title: "\(inputNewNickname!)", message: "입력하신 닉네임으로 변경할까요?", preferredStyle: .alert)
            let change = UIAlertAction(title: "변경", style: .default, handler: { _ in
                print("yes 클릭")
                // 유저의 userName 변경
                db.collection("UserData").document(userUid).updateData([
                    "userName" : inputNewNickname!
                ]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                        self.alert(title: "닉네임 변경 실패", message: "서버 정보를 불러오지 못했어요",  actiondTitle: "확인")
                    } else {
                        print("유저의 userName 변경")
                        self.alert(title: "닉네임 변경 완료", message: "\(inputNewNickname!)으로 닉네임을 변경했어요",  actiondTitle: "확인")
                        // 유저와 연결된 친구의 friendName 변경을 위해 유저의 pairFriendcode로 문서 이름 가져오기
                        db.collection("UserData").whereField("friendCode", isEqualTo: userPairFriendCode).getDocuments { (querySnapshot, error) in
                            if let error = error {
                                print("error: \(error)")
                                self.alert(title: "정보 불러오기 실패", message: "연결된 친구의 정보를 불러오지 못했어요",  actiondTitle: "확인")
                            } else {
                                var userPairFriendUid = "not read"
                                if let documents = querySnapshot?.documents {
                                    for document in documents {
                                        // 문서 이름은 연결된 친구의 uid와 일치하므로 userPairFriendUid 변수에 저장
                                        userPairFriendUid = document.documentID
                                    }
                                }
                                db.collection("UserData").document(userPairFriendUid).updateData(["friendName" : inputNewNickname!]){ err in
                                    if let err = err {
                                        print("Error updating document: \(err)")
                                        self.alert(title: "변경 오류", message: "연결된 상대방에게 변경된 닉네임으로 나타나지 않아요",  actiondTitle: "확인")
                                    } else {
                                        print("연결된 친구의 friendName 변경")
                                        self.alert(title: "변경 완료", message: "연결된 상대방에게도 변경된 닉네임으로 나타나요",  actiondTitle: "확인")
                                    }
                                }
                            }
                        }
                    }
                }
                
                let changeDone = UIAlertController(title: "닉네임 변경", message: "완료되었습니다", preferredStyle: .alert)
                let copyLink = UIAlertAction(title: "확인", style: .default)
                changeDone.addAction(copyLink)
                self.present(changeDone, animated: true)
                
            })
            let close = UIAlertAction(title: "아니오", style: .destructive, handler: { _ in
                print("no 클릭")
            })
            sheet.addAction(change)
            sheet.addAction(close)
            self.present(sheet, animated: true)
            
            DispatchQueue.main.async { // '보내기' 이후 title, content 내용 초기화
                self.nicknameChangeTextField.text = ""
            }
        }
    }
    
    @IBAction func manualButtonPressed(_ sender: UIButton) {
        // 웹페이지로 이동
    }
    
    @IBAction func disconnectWIthFriendButtonPressed(_ sender: UIButton) {
        // 친구와 연결 끊기 버튼 클릭
        
        // 나의 pairFriendCode 초기화
        let myUid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")!
        db.collection("UserData").document(myUid).updateData(
            ["pairFriendCode" : "none"]) // DB 상 나의 pairFriendCode 초기화
        { (err) in // 나의 UserData에서 pairFriendCode를 inputPairFriendCode로 업데이트
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                UserDefaults.shared.setValue("none", forKey: "pairFriendCode") // UserDefaults의 pairFriendCode 초기화
            }
        }
        
//        // 상대방의 pairFriendCode를 초기화
//        let pairFriendDocumentId = UserDefaults.shared.string(forKey: "documentID") ?? "none"
//        // pairFriend의 uid이자, documentID임
//
//        db.collection("UserData").document(pairFriendDocumentId).updateData(
//            ["pairFriendCode" : "none"])
//        { (err) in // 나의 UserData에서 pairFriendCode를 inputPairFriendCode로 업데이트
//            if let err = err {
//                print("Error updating document: \(err)")
//            } else {
//                print("Document successfully updated")
//            }
//        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let NavigationController = storyboard.instantiateViewController(identifier: "NavigationController")
        NavigationController.modalPresentationStyle = .fullScreen
        self.show(NavigationController, sender: nil)
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        // 로그아웃 버튼 클릭
        // 구글로 로그인했는지, 애플로 로그인했는지 구분해서, if 문을 통한 로그아웃을 구현해야함.
        // 유저가 어떤 소셜 로그인을 이용했는지 확인
        if let currentUser = Auth.auth().currentUser {
            if let providerID = currentUser.providerData.first?.providerID {
                UserDefaults.shared.setValue("none", forKey: "friendCode")
                UserDefaults.shared.setValue("none", forKey: "pairFriendCode")
                
                if providerID == "apple.com" {
                    // 애플 계정으로 로그인한 경우
                    print("유저가 애플 계정으로 로그인함")
                    // 애플 로그아웃
                    signupVC.removeAppleLoggedIn()
                } else if providerID == "google.com" {
                    // 구글 계정으로 로그인한 경우
                    print("유저가 구글 계정으로 로그인함")
                    // 구글 로그아웃
                    GIDSignIn.sharedInstance.signOut()
                    GIDSignIn.sharedInstance.disconnect()
                }
            }
        }
        
        let firebaseAuth = Auth.auth()
        print("firebaseAuth: \(firebaseAuth)")
        do {
            try firebaseAuth.signOut()
            print("로그아웃 성공")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let NavigationController = storyboard.instantiateViewController(identifier: "NavigationController")
            NavigationController.modalPresentationStyle = .fullScreen
            self.show(NavigationController, sender: nil)
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func helpButtonPressed(_ sender: UIButton) {
        // 웹페이지로 이동
    }
    
    @IBAction func quitButtonPressed(_ sender: UIButton) {
        // 회원 탈퇴 버튼
        if let currentUser = Auth.auth().currentUser {
            if let providerID = currentUser.providerData.first?.providerID {
                if providerID == "apple.com" {
                    // 애플 계정으로 로그인한 경우
                    print("유저가 애플 계정으로 로그인함")
                    // 애플 로그아웃
                    signupVC.removeAppleLoggedIn()
                } else if providerID == "google.com" {
                    // 구글 계정으로 로그인한 경우
                    print("유저가 구글 계정으로 로그인함")
                    // 구글 로그아웃
                    GIDSignIn.sharedInstance.signOut()
                    GIDSignIn.sharedInstance.disconnect()
                }
            }
        }
        let user = Auth.auth().currentUser
        
        user?.delete { error in
            if let error = error {
                print("error: \(error)")
            } else {
                // Account deleted.
                print("탈퇴 완료")
                // LetterData에서 유저가 쓴 데이터 찾아서 삭제...는 탈퇴후 30일쯤에 진행하는 걸로
                
                // UserData 내에서 해당 유저의 정보 삭제
                let uid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")!
                self.deleteUserData(uid: uid)
            }
        }
    }
    
    func deleteLetterData(friendCode: String) {
        db.collection("LetterData").whereField("sender", isEqualTo: friendCode).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("error: \(error)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        doc.reference.delete() { error in
                            if let error = error {
                                print("Error deleting document: \(error)")
                            } else {
                                print("Document deleted successfully")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteUserData(uid: String) {
        db.collection("UserData").document(uid).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
                
                // UserData 활용목적
                UserDefaults.shared.removeObject(forKey: "userName")
                UserDefaults.shared.removeObject(forKey: "userEmail")
                UserDefaults.shared.removeObject(forKey: "friendCode")
                UserDefaults.shared.removeObject(forKey: "friendName")
                UserDefaults.shared.removeObject(forKey: "ALetterFromLateNightUid")
                UserDefaults.shared.removeObject(forKey: "pairFriendCode")
                UserDefaults.shared.removeObject(forKey: "signupTime")
                // 상대방의 document 확인 목적
                UserDefaults.shared.removeObject(forKey: "DocumentID")
                // 소셜 로그인 확인 목적
                UserDefaults.shared.removeObject(forKey: "isAppleLoggedIn")
                // 오늘 편지 보냈는지 여부 확인 목적
                UserDefaults.shared.removeObject(forKey: "todayLetterTitle")
                UserDefaults.shared.removeObject(forKey: "todayLetterContent")
                UserDefaults.shared.removeObject(forKey: "todayLetterUpdateTime")
                // 위젯 전달 목적
                UserDefaults.shared.removeObject(forKey: "latestTitle")
                UserDefaults.shared.removeObject(forKey: "latestContent")
                UserDefaults.shared.removeObject(forKey: "latestUpdateDate")
                UserDefaults.shared.removeObject(forKey: "latestLetterColor")
                UserDefaults.shared.removeObject(forKey: "latestEmoji")
                UserDefaults.shared.removeObject(forKey: "latestSender")
                
                self.moveToMain()
            }
        }
    }
    
}

