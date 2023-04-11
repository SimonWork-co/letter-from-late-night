//
//  ConnectViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/23.
//

import UIKit
import Firebase

var inputDocumentID = ""
var inputFriendName : String = ""

extension ConnectTypingViewController {
    func inputDocumentIDcheck() {
        print("inputDocumentID: \(inputDocumentID)")
        UserDefaults.shared.set("\(inputDocumentID)", forKey: "documentID")
        UserDefaults.shared.synchronize()
    }
}

class ConnectTypingViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    let waitingVC = WaitingViewController()
    let inputFriendCode : String = UserDefaults.shared.object(forKey: "friendCode") as! String
    
    @IBOutlet weak var pairFriendCodeTextField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var myFriendCode: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Auth.auth().currentUser?.uid : \(Auth.auth().currentUser!.uid)")
        myFriendCode.text = inputFriendCode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("ViewController의 view가 Load됨")
        
        //startButton.layer.cornerRadius = 10
        //startButton.layer.borderWidth = 0.75
    }
    func currentUserDoc() -> DocumentReference? {
        if Auth.auth().currentUser != nil {
            return db.collection("UserData").document(Auth.auth().currentUser!.uid)
        }
        return nil
    }
    
    func friendCodeCheck() {
        
        if let inputPairFriendCode = pairFriendCodeTextField.text { // 내가 입력한 pairFriendCode가 DB상에 존재하는지 확인
            if inputPairFriendCode == inputFriendCode {
                print("나의 친구코드가 아닌 상대방의 친구코드를 입력해주세요")
                let sheet = UIAlertController(title: "다른 친구코드를 입력해주세요!", message: "나의 친구코드가 아닌 상대방의 친구코드를 입력해주세요", preferredStyle: .alert)
                sheet.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    print("yes 클릭")
                }))
                DispatchQueue.main.async { // '보내기' 이후 title, content 내용 초기화
                    self.pairFriendCodeTextField.text = ""
                }
                self.present(sheet, animated: true)
            } else {
                db.collection("UserData").whereField("friendCode", isEqualTo: inputPairFriendCode).getDocuments() { (querySnapshot, error) in
                    
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        let documents = querySnapshot!.documents
                        if documents.isEmpty == false {
                            print("friend 코드가 db 상에 있음")
                            for document in documents {
                                let documentID = document.documentID
                                print("\(documentID) => \(document.data())")
                                let data = document.data()
                                inputDocumentID = documentID // 상대방의 uid
                                if let friendName = data["userName"] as? String {
                                    // 상대방의 UserName 즉, 나의 friendName
                                    print("friendName: \(friendName)")
                                    inputFriendName = friendName
                                    print("inputFriendName: \(inputFriendName)")
                                    
                                    let uid : String = UserDefaults.shared.object(forKey: "ALetterFromLateNightUid") as! String // 나의 친구코드
                                    let dcRef = self.db.collection("UserData").document("\(uid)")
                                    
                                    // db 상 나의 데이터
                                    dcRef.updateData([
                                        "pairFriendCode" : inputPairFriendCode,
                                        "friendName" : friendName
                                    ])  { (err) in // 나의 UserData에서 pairFriendCode를 inputPairFriendCode로 업데이트
                                        if let err = err {
                                            print("Error updating document: \(err)")
                                        } else {
                                            print("Document successfully updated")
                                            self.segueToWaitingVC()
                                        }
                                    }
                                } else {
                                    print("NO FriendName!")
                                }
                                
                                return
                            }
                        } else {
                            let sheet = UIAlertController(title: "친구가 아직 가입하지 않은 것 같아요", message: "친구에게 앱 다운로드 링크를 보낼까요?", preferredStyle: .actionSheet)
                            let sendInvitation = UIAlertAction(title: "보내기", style: .default, handler: { _ in
                                print("yes 클릭")
                            })
                            let close = UIAlertAction(title: "닫기", style: .destructive, handler: nil)
                            sheet.addAction(sendInvitation)
                            sheet.addAction(close)
                            self.present(sheet, animated: true)
                            
                            DispatchQueue.main.async { // '보내기' 이후 title, content 내용 초기화
                                self.pairFriendCodeTextField.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
    
    func segueToWaitingVC() {
        inputDocumentIDcheck()
        // waitingVC 화면으로 보내기
        performSegue(withIdentifier: "connectTypingToWaiting", sender: nil)
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        friendCodeCheck()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "connectTypingToWaiting" {
            let nextVC = segue.destination as? WaitingViewController
            
            nextVC?.inputFriendName = inputFriendName
        }
    }
}


//1.
// https://itunes.apple.com/kr/app/apple-store/{app이름}
//iOS의 경우 app이름이 id1234123123 이런식으로 조합된다.
//
//2. market shceme을 사용하기
//itms-apps://itunes.apple.com/kr/app/apple-store/{app이름}
