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
    func alert(title: String, message: String, actionTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default)
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }
    
    func moveToMain(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(identifier: "SecondNavigationController")
        mainViewController.modalPresentationStyle = .fullScreen
        self.show(mainViewController, sender: nil)
    }
    
    func moveToSignup() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewController(identifier: "NavigationController")
        mainViewController.modalPresentationStyle = .fullScreen
        self.show(mainViewController, sender: nil)
    }
}

class SettingViewController: UIViewController {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var nicknameChangeTextField: UITextField!
    @IBOutlet weak var nicknameChangeButton: UIButton!
    @IBOutlet weak var emailChangeLabel: UILabel!
    @IBOutlet weak var emailChangeButton: UIButton!
    
    @IBOutlet weak var nicknameChangeLabel: UILabel!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var manualButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    
    @IBOutlet weak var myFriendCodeLabel: UILabel!
    @IBOutlet weak var myFriendCode: UILabel!
    @IBOutlet weak var quitButton: UIButton!
    
    let signupVC = SignupViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 배너 광고 설정
        setupBannerViewToBottom(adUnitID: Constants.GoogleAds.settingVC)
        viewChange()
        
    }
    
    func viewChange() {
        
        let userName = UserDefaults.shared.string(forKey: "userName")!
        //userNameLabel.font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: 25)
        userNameLabel.text = "\(userName)님 안녕하세요"
        userNameLabel.asColor(targetStringList: [userName], color: .purple)

        let userFriendCode = UserDefaults.shared.string(forKey: "friendCode")!
        myFriendCode.text = userFriendCode
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
                // 유저의 userName 변경
                db.collection("UserData").document(userUid).updateData([
                    "userName" : inputNewNickname!
                ]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                        self.alert(title: "닉네임 변경 실패", message: "서버 정보를 불러오지 못했어요",  actionTitle: "확인")
                    } else {
                        print("유저의 userName 변경")
                        self.alert(title: "닉네임 변경 완료", message: "\(inputNewNickname!)으로 닉네임을 변경했어요",  actionTitle: "확인")
                        UserDefaults.shared.set(inputNewNickname, forKey: "userName")
                        
                        // 유저와 연결된 친구의 friendName 변경을 위해 유저의 pairFriendcode로 문서 이름 가져오기
                        db.collection("UserData").whereField("friendCode", isEqualTo: userPairFriendCode).getDocuments { (querySnapshot, error) in
                            if let error = error {
                                print("error: \(error)")
                                self.alert(title: "정보 불러오기 실패", message: "연결된 친구의 정보를 불러오지 못했어요",  actionTitle: "확인")
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
                                        self.alert(title: "변경 오류", message: "연결된 상대방에게 변경된 닉네임으로 나타나지 않아요",  actionTitle: "확인")
                                    } else {
                                        print("연결된 친구의 friendName 변경")
                                        self.alert(title: "변경 완료", message: "연결된 상대방에게도 변경된 닉네임으로 나타나요",  actionTitle: "확인")
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
    
    @IBAction func emailChangeButtonPressed(_ sender: UIButton) {
        
        let userEmail = UserDefaults.shared.string(forKey: "userEmail")!
        let uid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")!
        let placeholder = userEmail
        
        let alertController = UIAlertController(title: "변경할 이메일을 입력해주세요", message: "애플 로그인의 경우, 이메일 수집이 되지 않았을 수 있습니다", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "현재 이메일: \(userEmail)" // 텍스트 필드의 플레이스홀더를 현재 유저의 이메일로 설정
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            // 취소 액션 처리
        }
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            
            if let textField = alertController.textFields?.first, let inputText = textField.text {
                
                if inputText != nil && inputText.contains("@") {
                    db.collection("UserData").document(uid).updateData(
                        ["userEmail" : inputText]){ err in
                            if let err = err {
                                print("Error updating document: \(err)")
                                self.alert(title: "변경 오류", message: "이메일 변경에 실패했어요",  actionTitle: "확인")
                            } else {
                                print("이메일 변경 완료")
                                UserDefaults.shared.set(inputText, forKey: "userEmail")
                                self.alert(title: "변경 완료", message: "이메일이 변경되었습니다.",  actionTitle: "확인")
                            }
                        }
                } else {
                    self.alert(title: "이메일 형식이 유효하지 않습니다", message: "올바른 이메일 형식으로 입력해주세요", actionTitle: "확인")
                    DispatchQueue.main.async {
                        textField.text = ""
                    }
                }
            }
        }
        
        alertController.addAction(okAction)
        
        // Alert 창 표시
        present(alertController, animated: true, completion: nil)
        
    }
    
    
    @IBAction func manualButtonPressed(_ sender: UIButton) {
        // 웹페이지로 이동
    }
    
    @IBAction func disconnectWIthFriendButtonPressed(_ sender: UIButton) {
        // 친구와 연결 끊기 버튼 클릭
        // 나의 pairFriendCode 초기화
        let alertController = UIAlertController(title: "친구와 연결을 끊을까요?", message: "상대방에게는 알리지 않을게요", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "확인", style: .default) { _ in
            print("확인 클릭")
            
            let myUid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")!
            db.collection("UserData").document(myUid).updateData(
                ["pairFriendCode" : "no pairFriendCode",
                 "connectedTime" : Date() - (24 * 60 * 60)]
            ) // DB 상 나의 pairFriendCode, connectedTime 초기화
            
            { (err) in // 나의 UserData에서 pairFriendCode를 inputPairFriendCode로 업데이트
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    UserDefaults.shared.setValue("no pairFriendCode", forKey: "pairFriendCode") // UserDefaults의 pairFriendCode 초기화
                    UserDefaults.shared.setValue(Date() - (24 * 60 * 60), forKey: "connectedTime")
                    
                    self.moveToSignup()
                }
            }
        }
        alertController.addAction(action1)
        let action2 = UIAlertAction(title: "취소", style: .destructive)
        alertController.addAction(action2)
        self.present(alertController, animated: true)
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        // 로그아웃 버튼 클릭
        // 구글로 로그인했는지, 애플로 로그인했는지 구분해서, if 문을 통한 로그아웃을 구현해야함.
        // 유저가 어떤 소셜 로그인을 이용했는지 확인
        let alertController = UIAlertController(title: "로그아웃 하시겠어요?", message: "로그인 화면으로 이동할게요", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "확인", style: .default) { _ in
            print("확인 클릭")
            
            if let currentUser = Auth.auth().currentUser {
                if let providerID = currentUser.providerData.first?.providerID {
                    // 저장된 userDefaults 모두 삭제
                    removeUserDefaultsData()
                    
                    if providerID == "apple.com" {
                        // 애플 계정으로 로그인한 경우
                        print("유저가 애플 계정으로 로그인함")
                        // 애플 로그아웃
                        self.signupVC.removeAppleLoggedIn()
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
                self.moveToSignup()
                
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }
        alertController.addAction(action1)
        let action2 = UIAlertAction(title: "취소", style: .destructive)
        alertController.addAction(action2)
        self.present(alertController, animated: true)
    }
    
    @IBAction func helpButtonPressed(_ sender: UIButton) {
        // 웹페이지로 이동
    }
    
    @IBAction func quitButtonPressed(_ sender: UIButton) {
        // 회원 탈퇴 버튼
        let alertController = UIAlertController(title: "탈퇴하시겠어요?", message: "회원 정보가 삭제되면 복구할 수 없어요", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "확인", style: .default) { _ in
            print("확인 클릭")
            if let currentUser = Auth.auth().currentUser {
                if let providerID = currentUser.providerData.first?.providerID {
                    if providerID == "apple.com" {
                        // 애플 계정으로 로그인한 경우
                        print("유저가 애플 계정으로 로그인함")
                        // 애플 로그아웃
                        self.signupVC.removeAppleLoggedIn()
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
                    let friendCode = UserDefaults.shared.string(forKey: "friendCode")!
                    
                    self.deleteLetterData(friendCode: friendCode)
                    self.deleteUserData(uid: uid)
                    
                }
            }
        }
        alertController.addAction(action1)
        let action2 = UIAlertAction(title: "취소", style: .destructive)
        alertController.addAction(action2)
        self.present(alertController, animated: true)
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
                removeUserDefaultsData()
                // 소셜 로그인 확인 목적
                self.signupVC.removeAppleLoggedIn()
                
                self.moveToSignup()
            }
        }
    }
    
}

