//
//  SettingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/24.
//

import UIKit
import Firebase

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeNicknameButtonPressed(_ sender: UIButton) {
        
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
    
    @IBAction func manualButton(_ sender: UIButton) {
        
    }
    
    @IBAction func disconnectWIthFriendButton(_ sender: UIButton) {
        //withIdentifier = "signupToGuide"
        UserDefaults.shared.setValue("none", forKey: "pairFriendCode")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let NavigationController = storyboard.instantiateViewController(identifier: "NavigationController")
        NavigationController.modalPresentationStyle = .fullScreen
        self.show(NavigationController, sender: nil)
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("로그아웃 성공")
            //withIdentifier = "signToMain"
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let NavigationController = storyboard.instantiateViewController(identifier: "NavigationController")
            NavigationController.modalPresentationStyle = .fullScreen
            self.show(NavigationController, sender: nil)
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func helpButton(_ sender: UIButton) {
        
    }
    
    @IBAction func quitButton(_ sender: UIButton) {
        let user = Auth.auth().currentUser

        user?.delete { error in
          if let error = error {
            print("error: \(error)")
          } else {
            // Account deleted.
            print("탈퇴 완료")
              
              //withIdentifier = "signupToGuide"
              UserDefaults.shared.setValue("none", forKey: "pairFriendCode")
              
              // LetterData에서 유저가 쓴 데이터 찾아서 삭제
              
              // UserData 내에서 해당 유저의 정보 삭제
              let uid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")!
              self.deleteUserData(uid: uid)
              // 초기 화면으로 이동해야 함
              let storyboard = UIStoryboard(name: "Main", bundle: nil)
              let NavigationController = storyboard.instantiateViewController(identifier: "NavigationController")
              NavigationController.modalPresentationStyle = .fullScreen
              self.show(NavigationController, sender: nil)
              
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
            }
        }
    }
    
}
