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
    
    func sendUserdata(UserName: String?, UserEmail: String?) {
        
        if let UserName, let UserEmail {
            let uid = Auth.auth().currentUser?.uid ?? ""
            print(uid)
            let cryptedUid = sha256(uid)
            print(cryptedUid)
            let friendCode = String(cryptedUid.prefix(6))
            print(friendCode)
            let pairFriendCode = "none"
          
            db.collection("UserData").addDocument(data: [
                "userName": UserName,
                "userEmail": UserEmail,
                "friendCode": friendCode,
                "pairFriendCode": pairFriendCode,
                "signupTime": Date(),
                "letterCount": 0
            ]) { (error) in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Successfully saved data.")
                }
            }
            // UserDefaults.standard.set("저장할 데이터", forKey: "Key값")
            UserDefaults.standard.set(UserName, forKey: "userName")
            UserDefaults.standard.set(UserEmail, forKey: "userEmail")
            UserDefaults.standard.set(friendCode, forKey: "friendCode")
            UserDefaults.standard.set(pairFriendCode, forKey: "pairFriendCode")
            
        } else {
            print(UserName)
            print(UserEmail)
            print("애플 유저이며, 2번째 이상의 로그인 시도이므로 파이어베이스에 데이터 입력 없음")
            // 기존 유저인지 확인하기 위한 uid 등과 대조 필요 (또는 usertoken을 활용해야 할듯?)
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
        let inputUserEmail = appleIDCredential.email ?? ""
        let fullName = appleIDCredential.fullName
        let familyName = fullName?.familyName
        let givenName = fullName?.givenName
        let inputUserName = (fullName?.familyName ?? "")+" "+(fullName?.givenName ?? "")
    
        sendUserdata(UserName: inputUserName, UserEmail: inputUserEmail)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print ("Error Apple sign in: %@", error)
                return
            }

            let user = Auth.auth().currentUser
            if let user = user {
                // The user's ID, unique to the Firebase project.
                // Do NOT use this value to authenticate with your backend server,
                // if you have one. Use getTokenWithCompletion:completion: instead.
                let uid = user.uid
                let email = user.email
                let photoURL = user.photoURL
                print(uid)
                print(email)
                print(photoURL ?? "")
                //              var multiFactorString = "MultiFactor: "
                //              for info in user.multiFactor.enrolledFactors {
                //                multiFactorString += info.displayName ?? "[DispayName]"
                //                multiFactorString += " "
                //              }
            }
            print("애플 회원가입 후 로그인")
            // Main 화면으로 보내기
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let mainViewController = storyboard.instantiateViewController(identifier: "MainViewController")
            mainViewController.modalPresentationStyle = .fullScreen
            self.navigationController?.show(mainViewController, sender: nil)
        }
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
    @IBOutlet weak var googleSignupButton: GIDSignInButton!
    @IBOutlet weak var appleSignupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        googleSignupButton.layer.cornerRadius = 10
        googleSignupButton.layer.borderWidth = 0.75
        appleSignupButton.layer.cornerRadius = 10
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn() == true {
            GIDSignIn.sharedInstance.restorePreviousSignIn()
            performSegue(withIdentifier: "signupToMain", sender: nil)
            print("구글 자동 로그인")
        } else {}
        
        // it triggers apple reauthentication after google reauthentication.
        //startSignInWithAppleFlow()
        
    }
    
    @IBAction func btn(_ sender: UIButton) {
        self.performSegue(withIdentifier: "signupToMain", sender: self)
    }
    
    @IBAction func googleSignupButtonPressed(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in
            if let error = error {
                print("ERROR", error.localizedDescription)
                return
            }
            
            guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }
            guard let inputUserName = user?.profile?.name, let inputUserEmail = user?.profile?.email else { return }
            
            self.sendUserdata(UserName: inputUserName, UserEmail: inputUserEmail)
            
            //GIDSignIn을 통해 받은 idToken, accessToken으로 Firebase에 로그인
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            // Access token을 부여받음
            
            // 사용자가 처음으로 로그인하면 신규 사용자 계정이 생성되고 사용자가 로그인할 때 사용한 사용자 인증 정보(사용자 이름과 비밀번호, 전화번호 또는 인증 제공업체 정보)에 연결됩니다. 이 신규 계정은 Firebase 프로젝트의 일부로 저장되며 사용자의 로그인 방법에 관계없이 프로젝트 내 모든 앱에서 사용자를 식별하는 데 사용될 수 있습니다.
            Auth.auth().signIn(with: credential) { _, _ in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    // navigate to the ChatViewController
                    print("Successfully Signed Up!")
                    self.performSegue(withIdentifier: "signupToMain", sender: self)
                }
            }
        }
    }
    
    @IBAction func appleSignupButtonPressed(_ sender: UIButton) {
        startSignInWithAppleFlow()
    }
}
