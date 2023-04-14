//
//  ConnectViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/23.
//

import UIKit
import Firebase

var inputDocumentID = ""
var inputPairFriendName : String = ""

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
    let myFriendCode = UserDefaults.shared.string(forKey: "friendCode")!
    
    @IBOutlet weak var pairFriendCodeTextField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var myFriendCodeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Auth.auth().currentUser?.uid : \(Auth.auth().currentUser!.uid)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //startButton.layer.cornerRadius = 10
        //startButton.layer.borderWidth = 0.75
        myFriendCodeLabel.text = myFriendCode
    
    }
    
//    func userFriendCodeShowed(){
//        let uid = Auth.auth().currentUser?.uid
//        print("uid: \(uid)")
//
//        db.collection("UserData").document(uid!).getDocument { (document, error) in
//            if let document = document {
//                if let data = document.data(){
//                    let inputFriendCode = data["friendCode"] as! String
//                    self.myFriendCodeLabel.text = inputFriendCode
//                }
//            }
//        }
//    }
    
    func friendCodeCheck() {
        
        if let inputPairFriendCode = pairFriendCodeTextField.text {
            // 내가 입력한 pairFriendCode가 DB상에 존재하는지 확인
            if inputPairFriendCode == myFriendCode { // 본인의 친구코드를 그대로 입력한 경우 오류 메시지 출력
                print("나의 친구코드가 아닌 상대방의 친구코드를 입력해주세요")
                let sheet = UIAlertController(title: "다른 친구코드를 입력해주세요!", message: "나의 친구코드가 아닌 상대방의 친구코드를 입력해주세요", preferredStyle: .alert)
                sheet.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    print("yes 클릭")
                }))
                DispatchQueue.main.async { // '보내기' 이후 title, content 내용 초기화
                    self.pairFriendCodeTextField.text = ""
                }
                self.present(sheet, animated: true)
                
            } else { // 입력된 pairFriendCode를 검색
                db.collection("UserData").whereField("friendCode", isEqualTo: inputPairFriendCode).getDocuments() { (querySnapshot, error) in
                    
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        let documents = querySnapshot!.documents
                        if documents.isEmpty == false { // friendCode가 DB 상에 있는 경우에 해당
                            print("friend 코드가 db 상에 있음")
                            
                            for document in documents {
                                let documentID = document.documentID // document.documentID는 상대방의 uid로 설정되어 있음.
                                print("\(documentID) => \(document.data())")
                                let data = document.data()
                                inputDocumentID = documentID // 상대방의 uid(documentID)를 inputDocumentID로 설정
                                if let pairFriendName = data["userName"] as? String {
                                    // 상대방의 UserName 즉, 나의 pairfriend의 Name
                                    print("friendName: \(pairFriendName)")
                                    
                                    inputPairFriendName = pairFriendName
                                    print("inputFriendName: \(inputPairFriendName)")
                                    
                                    let uid : String = UserDefaults.shared.object(forKey: "ALetterFromLateNightUid") as! String // 나의 uid / document 이름
                                    let dcRef = self.db.collection("UserData").document("\(uid)")
                                    
                                    // db상 나의 데이터
                                    dcRef.updateData([
                                        "pairFriendCode" : inputPairFriendCode,
                                        "friendName" : pairFriendName
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
                        } else { // 없는 경우에는 제대로 된 코드 입력하라는 알림 필요.
                            let sheet = UIAlertController(title: "친구가 아직 가입하지 않은 것 같아요", message: "친구에게 앱 다운로드 링크를 보낼까요?", preferredStyle: .actionSheet)
                            let sendInvitation = UIAlertAction(title: "보내기", style: .default, handler: { _ in
                                print("yes 클릭")
                                // 여기서 다운로드 링크를 보여줘야 함. 유저가 복사하게끔 하는 것도 괜찮을듯?
                                // 다운로드 링크를 유저가 상대방에게 공유하고, 공유받은 상대방은 링크를 클릭해서 앱스토어로 이동
                                let downloadLink = UIAlertController(title: "다운로드 링크를 여기에 표시", message: "URL을 공유해주세요", preferredStyle: .actionSheet)
                                let copyLink = UIAlertAction(title: "복사", style: .default) { _ in
                                    UIPasteboard.general.string = "저장 할 텍스트"
                                }
                                
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
            
            nextVC?.inputPairFriendName = inputPairFriendName
        }
    }
}


//1.
// https://itunes.apple.com/kr/app/apple-store/{app이름}
//iOS의 경우 app이름이 id1234123123 이런식으로 조합된다.
//
//2. market shceme을 사용하기
//itms-apps://itunes.apple.com/kr/app/apple-store/{app이름}
