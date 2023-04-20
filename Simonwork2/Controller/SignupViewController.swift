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

var handle: AuthStateDidChangeListenerHandle!

var userDefaultsData = UserDefaultsData()
let userDefaultsDataSave = UserDefaultsData.Save()

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
    
    func sendUserData(UserName: String?, UserEmail: String?) { // 회원가입(첫 로그인) 시에만 작동해야 하는 함수
        
        if let UserName, let UserEmail {
            print("UserName: \(UserName)")
            print("UserEmail: \(UserEmail)")
            let uid = Auth.auth().currentUser?.uid ?? ""
            print("uid : \(String(describing: uid))")
            let cryptedUid = sha256(uid)
            print("cryptedUid: \(cryptedUid)")
            let friendCode = String(cryptedUid.prefix(6))
            print("friendCode: \(friendCode)")
            
            let friendName = "none"
            let pairFriendCode = "none"
            let signupTime = Date()

            db.collection("UserData").document(uid).getDocument { documentSnapshot, error in
                if let error = error {
                    print("error: \(error)")
                } else {
                    if let document = documentSnapshot, document.exists {
                        print("document: \(document)")
                    } else {
                        print("Document does not exist")
                    }
                }
            }
            
            db.collection("UserData").document("\(String(describing: uid))").setData([
                "userName": UserName,
                "userEmail": UserEmail,
                "uid": uid,
                "friendName" : friendName,
                "friendCode": friendCode,
                "pairFriendCode": pairFriendCode,
                "signupTime": signupTime,
                "letterCount": 0
            ]) { error in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Successfully saved data.")
                    
                    userDefaultsDataSave.userName(UserName: UserName)
                    userDefaultsDataSave.userEmail(UserEmail: UserEmail)
                    userDefaultsDataSave.uid(uid: uid)
                    userDefaultsDataSave.friendCode(friendCode: friendCode)
                    userDefaultsDataSave.friendName(friendName: friendName)
                    userDefaultsDataSave.pairFriendCode(pairFriendCode: pairFriendCode)
                    userDefaultsDataSave.signupTime(signupTime: signupTime)
                    UserDefaults.shared.set("none", forKey: "documentID")
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
            
            userDefaultsDataSave.userName(UserName: inputUserName)
            userDefaultsDataSave.userEmail(UserEmail: inputUserEmail)
            
            print("Apple FullName: \(fullName)")
            print("Apple familyName: \(familyName)")
            print("Apple givenName: \(givenName)")
            
            print("Apple inputUserName: \(inputUserName)")
            print("Apple inputUserEmail: \(inputUserEmail)")
        } else {
            inputUserName = "사용자"
            inputUserEmail = "No Email"
            
            userDefaultsDataSave.userName(UserName: inputUserName)
            userDefaultsDataSave.userEmail(UserEmail: inputUserEmail)
        }
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print ("Error Apple sign in: %@", error)
                return
            } else {
                
                if withIdentifier == "signupToGuide" {
                    self.sendUserData(UserName: inputUserName, UserEmail: inputUserEmail)
                    self.setAppleLoggedIn()
                    self.performSegue(withIdentifier: withIdentifier, sender: nil)
                } else if withIdentifier == "signupToConnectTyping" {
                    self.setAppleLoggedIn()
                    self.performSegue(withIdentifier: withIdentifier, sender: nil)
                }
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
    
    var userFriendCode: String? = "nil"
    var userPairFriendCode: String? = "nil"
    var userPairFriendDocumentID : String? = "nil"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //imageView.frame.origin.x = -120
        //imageView.frame.origin.y = 83
        
        //여기서 로그인 조회 필요. UserDefaults 를 조회하고, 거기에 데이터가 있으면 이를 불러와서 로그인함.
        loadUserData()
    }
    
    func loadUserData() { // 유저의 document를 DB에서 호출하여 친구코드와 상대방의 친구코드를 가져옴
        // 여기에 추가로 상대방의 친구코드를 이용해 상대방의 DocumentID를 가져와야함
        let db = Firestore.firestore()
        let currentUserUid = Auth.auth().currentUser?.uid ?? "none"
        print("currentUserUid: \(currentUserUid)")
        
        db.collection("UserData").document(currentUserUid).getDocument { (documentSnapshot, error) in
            if let error = error {
                print("Error: \(error)")
            } else {
                if let document = documentSnapshot, document.exists {
                    if let data = document.data() {
                        self.userFriendCode = data["friendCode"] as? String
                        print("self.userFriendCode: \(self.userFriendCode)")
                        UserDefaults.shared.set(self.userFriendCode ?? "none", forKey: "friendCode")
                        
                        self.userPairFriendCode = data["pairFriendCode"] as? String
                        print("self.userPairFriendCode: \(self.userPairFriendCode)")
                        UserDefaults.shared.set(self.userPairFriendCode ?? "none", forKey: "pairFriendCode")
                    }
            
                    db.collection("UserData").whereField("friendCode", isEqualTo: self.userPairFriendCode!).getDocuments { (querySnapshot, error) in
                        if let error = error {
                            print("error: \(error)")
                        } else {
                            if let documents = querySnapshot?.documents {
                                for document in documents {
                                    self.userPairFriendDocumentID = document.documentID
                                    UserDefaults.shared.set(self.userPairFriendDocumentID ?? "none", forKey: "documentID")
                                }
                            }
                        }
                    }
                    self.autoLogin()
                }
            }
        }
    }
    
    func autoLogin() { // 유저의 친구코드와 상대방의 친구코드, 상대방의 DocumentID를 UserDefault에 저장.
        // 이전에 회원가입 과정에서 친구코드 연결이 되다가 말았으면 ConnectTypingVC로 보내야 함
        let friendCode = UserDefaults.shared.object(forKey: "friendCode") as? String ?? "none"
        var pairFriendCode = UserDefaults.shared.object(forKey: "pairFriendCode") as? String
        if pairFriendCode != nil && !pairFriendCode!.isEmpty {
            print("documentID: \(pairFriendCode!)") // 저장된 값이 있는 경우 해당 값 출력
        } else {
            pairFriendCode = "none" // 저장된 값이 없는 경우 "none"을 다른 변수에 할당
            print("documentID: \(pairFriendCode)") // "none" 출력
        }
        
        var documentID = UserDefaults.shared.object(forKey: "documentID") as? String
        if documentID != nil && !documentID!.isEmpty {
            print("documentID: \(documentID!)") // 저장된 값이 있는 경우 해당 값 출력
        } else {
            documentID = "none" // 저장된 값이 없는 경우 "none"을 다른 변수에 할당
            print("documentID: \(documentID ?? "none")") // "none" 출력
        }
        
        // documentID는 ConnectTypingVC에서 불러온 것이며, 상대방의 uid이자 상대방 DB의 문서명이다.
        // 1) 최초 진입유저 또는 회원 탈퇴자의 경우 documentID가 "none"
        // 2) 회원가입 미완료자(친구코드를 입력하지 않은 사람) 또는 상대방과 연결을 끊은 경우 documentID가 "none"
        // 3) 자동로그인 해당 유저의 경우 유효한 documentID가 존재.
        print("friendCode: \(friendCode)")
        print("pairFriendCode: \(pairFriendCode)")
        print("documentID: \(documentID)")
        
        
        // 현재 로그인하는 유저의 정보를 가져옴 0은 로그인하는 유저의 friendCode, 1은 로그인하는 유저의 pairfriendCode
        // 이를 통해 구글 로그인인지, 애플 로그인인지를 구분함.
        let dbUserFriendCode = userFriendCode!
        print("dbUserFriendCode: \(dbUserFriendCode)")
        let dbUserPairFriendCode = userPairFriendCode!
        print("dbUserPairFriendCode: \(dbUserPairFriendCode)")
        
        var friendCodeExists = 0
        var pairFriendCodeExists = 0
        
        // friendCode == "none" : 로그인 이력 없음 또는 로그아웃함
        // friendCode != "none" : 로그인 성공했었음 (구글 로그인인지, 애플 로그인인지는 검증 필요)
            // friendCode != "none" && friendCode != dbUserFriendCode 이면 이전 소셜 로그인과 현재 로그인 방식 다름
            // 즉, 별개의 유저로 인식 필요
        // dbUserFriendCode == "nil" : 로그인 이력 없음
        
        if friendCode == "none" && dbUserFriendCode == "nil" {
            // 로그인 이력이 없는 최초 가입 유저임
            friendCodeExists = 0
        } else if friendCode != "none" && dbUserFriendCode == "nil" {
            // 회원가입 중에 로그인 직후 이탈했으며, db 상에 기록되지 않은 유저임
            friendCodeExists = 0
        } else if friendCode == "none" && dbUserFriendCode != "nil"{
            // 유저가 로그아웃하면서 friendCode를 초기화하였으나, db에는 친구코드가 남아있는 상황
            friendCodeExists = 1
        } else if friendCode == dbUserFriendCode {
            // userDefault 상의 친구코드와 db 상의 친구코드가 일치하면 그대로 진행가능
            friendCodeExists = 1
        } else if friendCode != "none" && friendCode != dbUserFriendCode {
            // 불일치하면 이전에 가입한 적 있으나 소셜 로그인을 다르게 한 상태임
            friendCodeExists = 1
            userDefaultsDataSave.friendCode(friendCode: dbUserFriendCode ?? "") // 여기서 "" 값으로 들어가고 있음
        }
        
        // pairFriendCode == "none" : 친구코드를 입력한 적이 없음 또는 로그아웃함
        // pairFriendCode != "none" : 친구코드를 입력한 적이 있음 (구글 로그인인지, 애플 로그인인지는 검증 필요)
        // dbUserPairFriendCode == "nil" : 친구코드를 입력한 적이 없음
        // dbUserPairFriendCode != "nil" : 친구코드를 입력한 적이 있음 (구글 로그인인지, 애플 로그인인지는 검증 필요)
        
        if pairFriendCode! == "none" && dbUserPairFriendCode == "nil" {
            // 친구코드 기입 이력이 없는 최초 가입 유저임
            pairFriendCodeExists = 0
        } else if pairFriendCode! == dbUserPairFriendCode {
            // userDefault 상의 pairFriendCode와 db 상의 pairFriendCode 일치하면 그대로 진행가능.
            pairFriendCodeExists = 1
        } else if pairFriendCode! == "none" && pairFriendCode != "nil" {
            // 유저가 로그아웃하면서 pairFriendCode를 초기화하였으나, db에는 상대방의 친구코드가 남아있는 상황
            pairFriendCodeExists = 1
        } else if pairFriendCode! != "none" && pairFriendCode != dbUserPairFriendCode {
            // 불일치하면 이전에 가입한 적 있으나 소셜 로그인을 다르게 한 상태임
            pairFriendCodeExists = 1
            userDefaultsDataSave.friendCode(friendCode: dbUserPairFriendCode ?? "")
        }
        
        var exists = (friendCodeExists, pairFriendCodeExists)
        
        // 상대방의 documentID를 조회하여 상대방의 pairFriendCode가 나의 친구코드로 등록이 되었는지를 확인
        db.collection("UserData").document(documentID!).getDocument { (documentSnapshot, error) in
            if let error = error {
                print("Error: \(error)")
            } else {
                if let document = documentSnapshot {
                    if let data = document.data(){
                        let isPairFriendCodeExists = data["pairFriendCode"] as! String
                        if isPairFriendCodeExists == friendCode {
                            // 상대방의 db 상의 pairFriendCode가 나의 friendCode로 되어있음
                            pairFriendCodeExists = 1
                        } else if isPairFriendCodeExists == "none" {
                            // 상대방의 db 상의 pairFriendCode으로 등록된 내용이 없음
                            // 내가 상대방의 friendCode를 나의 pairFriendCode로 설정했더라도 상대방의 pairFriendCode가 none이라면, waitingVC에서 내가 도중에 이탈한 경우에 해당함. 따라서, 친구코드를 다시 입력하게끔 유도 필요
                            pairFriendCodeExists = 0
                        } else {
                            // 상대방의 db 상의 pairFriendCode가 내가 아닌 다른 사람의 friendCode로 되어있음
                            // 내가 상대방에게 요청을 한 사이, 상대방이 다른 사람과 연결이 되어버린 상태임. connectTypingVC으로 유저를 유도하여 친구코드를 다시 입력하게끔 할 필요있음.
                            pairFriendCodeExists = 0
                        }
                    }
                }
            }
        }
        
        switch exists
        {
        case (0,0) :
            // case0: 유저의 friendCode && pairfriendCode 가 없으면 최초 진입유저 또는 회원 탈퇴자
            // login 버튼을 클릭하게끔 내버려둠
            withIdentifier = "signupToGuide"
            print("case0: 유저의 friendCode && pairfriendCode 가 없으면 최초 진입유저 또는 회원 탈퇴자")
            print("exists: \(exists)")
        case (1,0):
            // case1 유저의 friendCode 는 있으나 pairfriendCode 가 없으면 회원가입 미완료자 또는 상대방과 연결을 끊은 경우
            // 로그인 버튼 클릭 후 pairFrinedCode 입력 화면으로 이동 필요 (signupToConnectTyping)
            // !!단, 저장된 friendCode가 로그인 버튼 클릭 후 생성되는 friendCode와 다른 경우에는 db로 부터 정보를 불러와야함!!
            withIdentifier = "signupToConnectTyping"
            print("case1 유저의 friendCode 는 있으나 pairfriendCode 가 없으면 회원가입 미완료자 또는 상대방과 연결을 끊은 경우")
            print("exists: \(exists)")
        case (0,1):
            // 유저의 친구코드가 있으나, auth.currentUser의 로그인 정보와 다름.
            // 만약 구글 로그인을 했는데, (0,1)이 나오면 이전에 애플 로그인을 한 것이며, 별개의 유저로 간주가 필요함.
            // pairFriendCode도 새로운 것으로 인식 필요
            // 로그아웃 시 해당 케이스 발생함
            print("exists: \(exists)")
        case (1,1):
            // case2 유저의 friendCode && pairfriendCode 가 있으면 자동로그인 해당 유저
            // MainViewController로 곧장 이동 필요
            // !!단, 저장된 friendCode가 로그인 버튼 클릭 후 생성되는 friendCode와 다른 경우에는 db로 부터 정보를 불러와야함!!
            print("case2 유저의 friendCode && pairfriendCode 가 있으면 자동로그인 해당 유저")
            print("exists: \(exists)")
            // 구글 또는 애플 자동 로그인 실행 위치
            
            if let currentUser = Auth.auth().currentUser {
                if let providerID = currentUser.providerData.first?.providerID {
                    if providerID == "apple.com" {
                        // 애플 계정으로 로그인한 경우
                        print("유저가 애플 계정으로 로그인함")
                        // 애플 자동 로그인
                        appleAutoLogin()
                    } else if providerID == "google.com" {
                        // 구글 계정으로 로그인한 경우
                        print("유저가 구글 계정으로 로그인함")
                        // 구글 자동 로그인
                        googleAutoLogin()
                    }
                }
            }
        default:
            print("")
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
        } else if isAppleLoggedIn() == false {
            
        }
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
            
            userDefaultsDataSave.userName(UserName: inputUserName)
            userDefaultsDataSave.userEmail(UserEmail: inputUserEmail)
            
            //GIDSignIn을 통해 받은 idToken, accessToken으로 Firebase에 로그인
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken) // Access token을 부여받음
            
            Auth.auth().signIn(with: credential) { result, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    
                    if withIdentifier == "signupToGuide" {
                        self.sendUserData(UserName: inputUserName, UserEmail: inputUserEmail)
                        self.performSegue(withIdentifier: withIdentifier, sender: nil)
                    } else if withIdentifier == "signupToConnectTyping" {
                        self.performSegue(withIdentifier: withIdentifier, sender: nil)
                    }
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
