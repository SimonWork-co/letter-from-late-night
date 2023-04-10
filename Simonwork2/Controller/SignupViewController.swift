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

let db = Firestore.firestore() //initialize Cloud Firestore
var userdata: [UserData] = []
var withIdentifier : String = ""

var loginOrNot : Bool = true // true : 로그인한 상태, false : 로그인 안된 상태
var handle: AuthStateDidChangeListenerHandle!

var userDefaultsData = UserDefaultsData()
let userDefaultsDataSave = UserDefaultsData.Save()
let connectTypingVC = ConnectTypingViewController()

let mainVC = MainViewController()

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
    
    func sendUserData(UserName: String!, UserEmail: String!) { // 회원가입(첫 로그인) 시에만 작동해야 하는 함수
        
        if let UserName, let UserEmail {
            let uid = Auth.auth().currentUser?.uid ?? ""
            print("uid : \(String(describing: uid))")
            let cryptedUid = sha256(uid)
            print("cryptedUid: \(cryptedUid)")
            let friendCode = String(cryptedUid.prefix(6))
            print("friendCode: \(friendCode)")
            //connectTypingVC.inputFriendCode = friendCode
            let friendName = "none"
            let pairFriendCode = "none"
            let signupTime = Date()
            
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
                }
            }
            // UserDefaults.standard.set("저장할 데이터", forKey: "Key값")
            //            UserDefaults.standard.set(UserName, forKey: "userName")
            //            UserDefaults.standard.set(UserEmail, forKey: "userEmail")
            //            UserDefaults.standard.set(friendCode, forKey: "friendCode")
            //            UserDefaults.standard.set(friendName, forKey: "friendName")
            //            UserDefaults.standard.set(uid, forKey: "ALetterFromLateNightUid")
            //            UserDefaults.standard.set(pairFriendCode, forKey: "pairFriendCode")
            //            UserDefaults.standard.set(signupTime, forKey: "signupTime")
            userDefaultsDataSave.userName(UserName: UserName)
            userDefaultsDataSave.userEmail(UserEmail: UserEmail)
            userDefaultsDataSave.uid(uid: uid)
            userDefaultsDataSave.friendCode(friendCode: friendCode)
            userDefaultsDataSave.friendName(friendName: friendName)
            userDefaultsDataSave.pairFriendCode(pairFriendCode: pairFriendCode)
            userDefaultsDataSave.signupTime(signupTime: signupTime)
            UserDefaults.shared.set("", forKey: "documentID")
            UserDefaults.shared.synchronize()
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
            inputUserName = (fullName.familyName)!+" "+(fullName.givenName)!
            inputUserEmail = email
            
            print("Apple FullName: \(fullName)")
            print("Apple familyName: \(familyName)")
            print("Apple givenName: \(givenName)")
            
            print("Apple inputUserName: \(inputUserName)")
            print("Apple inputUserEmail: \(inputUserEmail)")
        } else {
            inputUserName = "사용자"
            inputUserEmail = "No Email"
        }
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print ("Error Apple sign in: %@", error)
                return
            } else {
                if withIdentifier == "signupToConnect" {
                    self.performSegue(withIdentifier: "signupToConnect", sender: nil)
                } else if withIdentifier == "signupToMain" {
                    userDefaultsData.receivedData = Auth.auth().currentUser
                    self.moveToMain()
                    //self.performSegue(withIdentifier: "signupToMain", sender: nil)
                }
            }
        }
        //        UserDefaults.standard.removeObject(forKey: "userName")
        //        UserDefaults.standard.removeObject(forKey: "userEmail")
        //        UserDefaults.standard.removeObject(forKey: "friendCode")
        //        UserDefaults.standard.removeObject(forKey: "friendName")
        //        UserDefaults.standard.removeObject(forKey: "ALetterFromLateNightUid")
        //        UserDefaults.standard.removeObject(forKey: "pairFriendCode")
        //        UserDefaults.standard.removeObject(forKey: "pairFriendCode")
        // 위의 removeObject 함수는 유저가 최초로 로그인하는 상황을 가정하기 위해 작성됨. 실제 배포 시에는 해당 함수들의 위치를 옮길 필요가 있음
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
    
    
    //emailTextField passwordTextField signupButton
    @IBOutlet weak var googleSignupButton: UIButton!
    @IBOutlet weak var appleSignupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //googleSignupButton.layer.cornerRadius = 10
        //googleSignupButton.layer.borderWidth = 0.75
        //appleSignupButton.layer.cornerRadius = 10
        //googleAutoLogin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // print("ViewController의 view가 Load됨")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // print("ViewController의 view가 Load됨")
        
    }
    
    func googleAutoLogin() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() == true {
            GIDSignIn.sharedInstance.restorePreviousSignIn()
            moveToMain()
            print("구글 자동 로그인")
        } else {}
    }
    
    @IBAction func btn(_ sender: UIButton) {
        moveToMain()
    }
    
    @IBAction func googleSignupButtonPressed(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in // 구글로 로그인 승인 요청
            if let error = error {
                print("ERROR", error.localizedDescription)
                return
            }
            
            guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
            inputUserName = (user?.profile?.name)!
            inputUserEmail = (user?.profile?.email)!
            
            //GIDSignIn을 통해 받은 idToken, accessToken으로 Firebase에 로그인
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken) // Access token을 부여받음
            
            // 사용자가 처음으로 로그인하면 신규 사용자 계정이 생성되고 사용자가 로그인할 때 사용한 사용자 인증 정보(사용자 이름과 비밀번호, 전화번호 또는 인증 제공업체 정보)에 연결됩니다.
            Auth.auth().signIn(with: credential) { _, _ in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    if withIdentifier == "signupToConnect" {
                        self.performSegue(withIdentifier: "signupToConnect", sender: nil)
                    } else if withIdentifier == "signupToMain" {
                        self.moveToMain()
                        //self.performSegue(withIdentifier: "signupToMain", sender: nil)
                    }
                }
            }
            print("구글 로그인")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "signupToConnect" {
            let nextVC = segue.destination as? ConnectViewController
            
            nextVC?.inputUserName = inputUserName
            nextVC?.inputUserEmail = inputUserEmail
            print("nextVC?.inputUserName : \(nextVC?.inputUserName)")
            print("nextVC?.inputUserEmail : \(nextVC?.inputUserEmail)")
        }
    }
    
    @IBAction func appleSignupButtonPressed(_ sender: UIButton) {
        startSignInWithAppleFlow()
    }
}
