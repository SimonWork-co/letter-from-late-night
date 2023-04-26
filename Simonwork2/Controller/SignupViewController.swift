//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseOAuthUI
import FirebaseEmailAuthUI
import FirebaseGoogleAuthUI
import AuthenticationServices
import CryptoKit

fileprivate var currentNonce: String?

let db = Firestore.firestore()
var userdata: [UserData] = []
var withIdentifier : String = ""

var inputUserName = ""
var inputUserEmail = ""

extension SignupViewController {
    
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        // request 요청을 했을 때 none가 포함되어서 릴레이 공격을 방지
        // 추후 파베에서도 무결성 확인을 할 수 있게끔 함
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func sendUserData(UserName: String?, UserEmail: String?) { // 회원가입(첫 로그인) 시에만 작동
        
        withIdentifier = "signupToGuide"
        
        if let UserName, let UserEmail {
            let uid = Auth.auth().currentUser?.uid ?? "no uid"
            let cryptedUid = sha256(uid)
            let friendCode = String(cryptedUid.prefix(6))
            
            let friendName = "no FriendName"
            let pairFriendCode = "no pairFriendCode"
            let signupTime = Date()
            
            let documentID = "no documentID"
            let connectedTime = Date() - (24 * 60 * 60)
            let todayLetterTitle = "no todayLetterTitle"
            let todayLetterContent = "no todayLetterContent"
            let todayLetterUpdateTime = Date() - (24 * 60 * 60)
            
            UserDefaultsData(
                UserName: UserName,
                UserEmail: UserEmail,
                friendCode: friendCode,
                friendName: friendName,
                uid: uid,
                pairFriendCode: pairFriendCode,
                signupTime: signupTime,
                documentID: documentID,
                connectedTime: connectedTime,
                todayLetterTitle: todayLetterTitle,
                todayLetterContent: todayLetterContent,
                todayLetterUpdateTime: todayLetterUpdateTime
            )
            
            db.collection("UserData").document("\(String(describing: uid))").setData([
                "userName": UserName,
                "userEmail": UserEmail,
                "uid": uid,
                "friendName" : friendName,
                "friendCode": friendCode,
                "pairFriendCode": pairFriendCode,
                "signupTime": signupTime,
                "letterCount": 0,
                "documentID" : documentID,
                "connectedTime" : connectedTime,
                "todayLetterTitle" : todayLetterTitle,
                "todayLetterContent" : todayLetterContent,
                "todayLetterUpdateTime" : todayLetterUpdateTime
            ]) { error in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Successfully saved data.")
                    self.performSegue(withIdentifier: withIdentifier, sender: nil)
                }
            }
        }
    }
}

extension SignupViewController: ASAuthorizationControllerDelegate {
    // controller로 인증 정보 값을 받게 되면은, idToken 값을 받음
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        // nonce : 암호화된 임의의 난수, 단 한번만 사용 가능
        // 동일한 요청을 짧은 시간에 여러번 보내는 릴레이 공격 방지
        // 정보 탈취 없이 안전하게 인증 정보 전달을 위한 안전장치 // 안전하게 인증 정보를 전달하기 위해 nonce 사용
        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
            return }
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return }
        
        //MARK: - 유저 개인 정보 (최초 회원가입 시에만 유저 정보를 얻을 수 있으며, 2회 로그인 시부터는 디코딩을 통해 이메일만 추출 가능. 이름은 불가)
        // token들로 credential을 구성해서 auth signin 구성 (google과 동일)
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        if let fullName = appleIDCredential.fullName, let familyName = fullName.familyName, let givenName = fullName.givenName, let email = appleIDCredential.email {
            //inputUserName = (fullName.familyName)!+" "+(fullName.givenName)!
            inputUserName = fullName.givenName!
            inputUserEmail = email
            
            print("Apple FullName: \(fullName)")
            print("Apple familyName: \(familyName)")
            print("Apple givenName: \(givenName)")
            
            print("Apple inputUserName: \(inputUserName)")
            print("Apple inputUserEmail: \(inputUserEmail)")
        } else {
            inputUserName = "사용자"
            inputUserEmail = "No Email"
            
            print("Apple inputUserName: \(inputUserName)")
            print("Apple inputUserEmail: \(inputUserEmail)")
        }
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print ("Error Apple sign in: %@", error)
                return
            } else {
                let uid = Auth.auth().currentUser!.uid
                self.setAppleLoggedIn()
                self.loadUserData(userName: inputUserName, userEmail: inputUserEmail)
            }
        }
        print("애플 로그인")
    }
    
    // Apple ID 연동 실패 시
    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError _: Error) {
        // Handle error.
    }
}

extension SignupViewController : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

//MARK: - Class SignupViewController

class SignupViewController: UIViewController, FUIAuthDelegate {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //emailTextField passwordTextField signupButton
    @IBOutlet weak var googleSignupButton: UIButton!
    @IBOutlet weak var appleSignupButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //imageView.frame.origin.x = -120
        //imageView.frame.origin.y = 83
        
    }
    
    func loadUserData(userName: String, userEmail: String) { //여기서 로그인 조회 필요. DB에서 유저 정보를 조회하고, 거기에 데이터가 있으면 이를 불러와서 로그인함.
        // 유저의 document를 DB에서 호출하여 친구코드와 상대방의 친구코드를 가져옴
        // 여기에 추가로 상대방의 친구코드를 이용해 상대방의 DocumentID를 가져와야함
        let db = Firestore.firestore()
        let currentUserUid = Auth.auth().currentUser?.uid ?? "no uid"
        
        db.collection("UserData").document(currentUserUid).getDocument { (documentSnapshot, error) in
            if let error = error { // 나의 유저정보 로드
                print("Error: \(error)")
            } else {
                if let document = documentSnapshot, document.exists {
                    print("document가 exists한 상태임")
                    if let data = document.data() {
                        print("document의 data가 exists한 상태임")
                        
                        let UserName = data["userName"] as! String
                        UserDefaults.shared.set(UserName, forKey: "userName")
                        
                        let UserEmail = data["userEmail"] as! String
                        let UserFriendCode = data["friendCode"] as! String
                        let friendName = data["friendName"] as! String
                        let UserPairFriendCode = data["pairFriendCode"] as! String
                        let signup_Time = data["signupTime"] as! Timestamp
                        let signupTime = signup_Time.dateValue()
                        // uid는 currentUserUid로 대체
                        let documentID = data["documentID"] as! String
                        let connected_Time = data["connectedTime"] as! Timestamp
                        let connectedTime = connected_Time.dateValue()
                        
                        let todayLetterTitle = data["todayLetterTitle"] as! String
                        let todayLetterContent = data["todayLetterContent"] as! String
                        
                        let today_LetterUpdateTime = data["todayLetterUpdateTime"] as! Timestamp
                        let todayLetterUpdateTime = today_LetterUpdateTime.dateValue()
                        print("data: \(data)")
                        
                        db.collection("UserData").whereField("friendCode", isEqualTo: UserPairFriendCode).getDocuments { (querySnapshot, error) in
                            // 상대방의 정보 조회해서 documentID 추출 및 나의 친구코드와 일치하는지 확인
                            if let error = error {
                                print("error: \(error)")
                                // 친구의 정보가 없거나 불러오는데 오류가 발생함.
                            } else {
                                print("if let documents로 진입")
                                if let documents = querySnapshot?.documents {
                                    print("documents로 진입")
                                    print(documents)
                                    if documents != [] {
                                        for document in documents {
                                            print("document의 data로 진입")
                                            // 상대방의 documentID 추출
                                            let userPairFriendDocumentID = document.documentID
                                            
                                            let data = document.data()
                                            // 상대방의 pairFriendCode가 나의 friendCode와 일치하는지 확인
                                            let opponentFriendCode = data["friendCode"] as! String
                                            let opponentPairFriendCode = data["pairFriendCode"] as! String
                                            
                                            // 로드된 모든 정보를 userDefaults에 저장
                                            UserDefaultsData(
                                                UserName: UserName,
                                                UserEmail: UserEmail,
                                                friendCode: UserFriendCode,
                                                friendName: friendName,
                                                uid: currentUserUid,
                                                pairFriendCode: opponentFriendCode,
                                                signupTime: signupTime,
                                                documentID: userPairFriendDocumentID,
                                                connectedTime: connectedTime,
                                                todayLetterTitle: todayLetterTitle,
                                                todayLetterContent: todayLetterContent,
                                                todayLetterUpdateTime: todayLetterUpdateTime
                                            )
                                            print(UserDefaultsData(
                                                UserName: UserName,
                                                UserEmail: UserEmail,
                                                friendCode: UserFriendCode,
                                                friendName: friendName,
                                                uid: currentUserUid,
                                                pairFriendCode: opponentFriendCode,
                                                signupTime: signupTime,
                                                documentID: userPairFriendDocumentID,
                                                connectedTime: connectedTime,
                                                todayLetterTitle: todayLetterTitle,
                                                todayLetterContent: todayLetterContent,
                                                todayLetterUpdateTime: todayLetterUpdateTime
                                            ))
                                            
                                            if UserPairFriendCode == "no pairFriendCode" {
                                                // 회원가입 과정 중 pairFriendCode를 입력하지 않고 이탈 (connectTypingVC로 이동 필요)
                                                withIdentifier = "signupToConnectTyping"
                                                self.performSegue(withIdentifier: withIdentifier, sender: nil)
                                                break
                                            } else if UserPairFriendCode == opponentFriendCode && opponentPairFriendCode == UserFriendCode {
                                                // 나의 PairFriendCode가 상대방의 friendCode이면서, 상대방의 pairFriendCode가 나의 친구코드이므로 이는 나와 연결된 사람임을 뜻함.
                                                // 즉, 자동 로그인 대상. moveToMain
                                                self.moveToMain()
                                                break
                                            } else if UserPairFriendCode == opponentFriendCode && opponentPairFriendCode != UserFriendCode {
                                                // 나는 상대를 친구로 설정했으나, 상대는 나와 연결되어 있지 않음.
                                                // 다른 친구코드를 입력하게끔 안내 필요 (connectTypingVC로 이동)
                                                withIdentifier = "signupToConnectTyping"
                                                self.performSegue(withIdentifier: withIdentifier, sender: nil)
                                                break
                                            }
                                        }
                                    } else {// 친구의 정보가 없어서 빈 []를 불러옴
                                        // 상대방의 친구코드를 입력해야 하므로 signupToConnectTyping로 세그
                                        
                                        // 현재 아래에 적힌 documentID는 가데이터이므로 connectingVC에서 문서 조회 시 문서가 조회되지 않음.
                                        // 상대방의 친구코드가 아직 존재하지 않으므로 connectingVC에서 상대방의 문서를 조회한후 문서ID를 나의 userData의 documentID로 업데이트해야함
                                        UserDefaultsData(
                                            UserName: UserName,
                                            UserEmail: UserEmail,
                                            friendCode: UserFriendCode,
                                            friendName: friendName,
                                            uid: currentUserUid,
                                            pairFriendCode: UserPairFriendCode,
                                            signupTime: signupTime,
                                            documentID: documentID,
                                            connectedTime: connectedTime,
                                            todayLetterTitle: todayLetterTitle,
                                            todayLetterContent: todayLetterContent,
                                            todayLetterUpdateTime: todayLetterUpdateTime
                                        )
                                        print(UserDefaultsData(
                                            UserName: UserName,
                                            UserEmail: UserEmail,
                                            friendCode: UserFriendCode,
                                            friendName: friendName,
                                            uid: currentUserUid,
                                            pairFriendCode: UserPairFriendCode,
                                            signupTime: signupTime,
                                            documentID: documentID,
                                            connectedTime: connectedTime,
                                            todayLetterTitle: todayLetterTitle,
                                            todayLetterContent: todayLetterContent,
                                            todayLetterUpdateTime: todayLetterUpdateTime))
                                        withIdentifier = "signupToConnectTyping"
                                        self.performSegue(withIdentifier: withIdentifier, sender: nil)
                                    }
                                }
                            }
                        }
                        
                    }
                } else {
                    // 유저의 uid로 된 문서가 서버에 없으므로 가이드 페이지로 이동. 서버에는 더미 데이터를 넣어 테이블을 생성한다.
                    print("유저의 uid로 된 문서가 서버에 없으므로 가이드 페이지로 이동. 서버에는 더미 데이터를 넣어 테이블을 생성한다.")
                    self.sendUserData(UserName: userName, UserEmail: userEmail)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let googleSignupButton = googleSignupButton, let appleSignupButton = appleSignupButton {
            googleSignupButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
            googleSignupButton.layer.cornerRadius = 10
            googleSignupButton.layer.borderWidth = 0.75
            
            appleSignupButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 17)
            appleSignupButton.layer.cornerRadius = 10
            appleSignupButton.layer.borderWidth = 0.75
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    func googleAutoLogin() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() == true {
            GIDSignIn.sharedInstance.restorePreviousSignIn()
            moveToMain()
            print("구글 자동 로그인")
        } else {}
    }
    
    func appleAutoLogin() {
        if isAppleLoggedIn() == true {
            moveToMain()
        } else {}
    }
    
    func isAppleLoggedIn() -> Bool {
        return UserDefaults.shared.bool(forKey: "isAppleLoggedIn")
    }
    
    func setAppleLoggedIn() {
        UserDefaults.shared.set(true, forKey: "isAppleLoggedIn")
    }
    
    func removeAppleLoggedIn() {
        UserDefaults.shared.removeObject(forKey: "isAppleLoggedIn")
    }
    
    @IBAction func googleSignupButtonPressed(_ sender: Any) {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { (user, error) in
            // 구글로 로그인 승인 요청
            if let error = error {
                print("ERROR", error.localizedDescription)
                return
            }
            
            guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
            inputUserName = (user?.profile?.givenName)!
            inputUserEmail = (user?.profile?.email)!
            
            //GIDSignIn을 통해 받은 idToken, accessToken으로 Firebase에 로그인
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken) // Access token을 부여받음
            
            
            Auth.auth().signIn(with: credential) { result, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    let uid = Auth.auth().currentUser!.uid
                    self.loadUserData(userName: inputUserName, userEmail: inputUserEmail)
                }
                return
            }
            print("구글 로그인")
        }
    }
    
    @IBAction func appleSignupButtonPressed(_ sender: UIButton) {
        startSignInWithAppleFlow()
    }
}
