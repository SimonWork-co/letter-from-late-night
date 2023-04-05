//
//  ConnectViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/23.
//

import UIKit
import Firebase

var inputDocumentID = ""

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
                            inputDocumentID = documentID
                            
                            let uid : String = UserDefaults.shared.object(forKey: "ALetterFromLateNightUid") as! String
                            let dcRef = self.db.collection("UserData").document("\(uid)")
                            
                            dcRef.updateData([
                                "pairFriendCode" : inputPairFriendCode
                            ])  { (err) in // 나의 UserData에서 pairFriendCode를 inputPairFriendCode로 업데이트
                                if let err = err {
                                    print("Error updating document: \(err)")
                                } else {
                                    print("Document successfully updated")
                                }
                            }
                            self.segueToWaitingVC()
                            return
                        }
                    } else {
                        print("친구가 아직 가입하지 않은 것 같아요.\n친구에게 앱 다운로드 링크를 보낼까요?")
                        
                        DispatchQueue.main.async { // '보내기' 이후 title, content 내용 초기화
                            self.pairFriendCodeTextField.text = ""
                        }
                    }
                }
            }
        }
    }
    
    func segueToWaitingVC() {
        inputDocumentIDcheck()
        // waitingVC 화면으로 보내기
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let WaitingViewController = storyboard.instantiateViewController(identifier: "WaitingViewController")
        WaitingViewController.modalPresentationStyle = .fullScreen
        self.navigationController?.show(WaitingViewController, sender: nil)
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        friendCodeCheck()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "connectTypingToWaiting" {
            let nextVC = segue.destination as? ConnectTypingViewController
        }
    }
}


//1.
// https://itunes.apple.com/kr/app/apple-store/{app이름}
//iOS의 경우 app이름이 id1234123123 이런식으로 조합된다.
//
//2. market shceme을 사용하기
//itms-apps://itunes.apple.com/kr/app/apple-store/{app이름}
