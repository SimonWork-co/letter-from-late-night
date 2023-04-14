//
//  SettingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/24.
//

import UIKit
import Firebase

class SettingViewController: UIViewController {
    
    @IBOutlet weak var nicknameChangeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeNicknameButtonPressed(_ sender: UIButton) {
        let inputNewNickname = nicknameChangeTextField.text
        if inputNewNickname != nil {
            
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
