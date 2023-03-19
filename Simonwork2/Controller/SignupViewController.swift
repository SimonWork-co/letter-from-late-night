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
var userData = UserData()

let db = Firestore.firestore()
var data: [UserData] = []

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
    
    private func sha256(_ input: String) -> String {
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
}

extension SignupViewController: ASAuthorizationControllerDelegate {
    
    // controller로 인증 정보 값을 받게 되면은, idToken 값을 받음
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            // nonce : 암호화된 임의의 난수, 단 한번만 사용 가능
            // 동일한 요청을 짧은 시간에 여러번 보내는 릴레이 공격 방지
            // 정보 탈취 없이 안전하게 인증 정보 전달을 위한 안전장치
            
            // 이름
            userData.userName = appleIDCredential.fullName?.description ?? ""
            userData.userEmail = appleIDCredential.email?.description ?? ""
            // accessToken (Data -> 아스키 인코딩 -> 스트링)
            //let accessToken = String(data: appleIDCredential.identityToken!, encoding: .ascii) ?? ""
            
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                // 안전하게 인증 정보를 전달하기 위해 nonce 사용
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
                      
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
 
            // token들로 credential을 구성해서 auth signin 구성 (google과 동일)
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print ("Error Apple sign in: %@", error)
                    return
                }
                // User is signed in to Firebase with Apple.
                // Main 화면으로 보내기
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let mainViewController = storyboard.instantiateViewController(identifier: "MainViewController")
                mainViewController.modalPresentationStyle = .fullScreen
                self.navigationController?.show(mainViewController, sender: nil)
            }

        }
    }
}

extension SignupViewController : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

class SignupViewController: UIViewController, FUIAuthDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var googleSignupButton: GIDSignInButton!
    @IBOutlet weak var appleSignupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMessages()
    }
    
    func loadMessages() {
        
        db.collection("UserData")
            .order(by: "date")
            .addSnapshotListener { (querySnapshot, error) in
            
            self.data = []
            
            if let e = error {
                print("There was an issue retrieving data from Firestore. \(e)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let sender = data["sender"] as? String, let messageBody = data["body"] as? String {
                            let newUserData = UserData(userEmail: <#T##String#>, userName: <#T##String#>)
                            self.data.append(newUserData)
                        }
                    }
                }
            }
        }
    }
    
    func userNameFunc(userName: String) -> String! {
        let userName = userData.userName
        print(userName)
        return userName
    }
    
    func userEmailFunc(userEmail: String) -> String! {
        let userEmail = userEmail
        print(userEmail)
        return userEmail
    }
    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    print(e.localizedDescription)
                } else {
                    // navigate to the ChatViewController
                    self.performSegue(withIdentifier: "signupToMain", sender: self)
                }
            }
        }
    }
    
    @IBAction func googleSignupButtonPressed(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in
            if let error = error {
                print("ERROR", error.localizedDescription)
                return
            }
            
            guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                return }
            guard let userName = user?.profile?.name, let userEmail = user?.profile?.email else {
                return
            }
            
            userData.userName = userName // 유저 이름을 UserData에 저장
            userData.userEmail = userEmail // 유저 이름을 UserData에 저장
            
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
        // 애플 accessToken -> 구글 토큰 유효성 확인 및 프로필 정보 얻기
    }
    
    //    func reAuthentication() {
    //        // Initialize a fresh Apple credential with Firebase.
    //        let credential = OAuthProvider.credential(
    //          withProviderID: "apple.com",
    //          IDToken: appleIdToken,
    //          rawNonce: rawNonce
    //        )
    //        // Reauthenticate current Apple user with fresh Apple credential.
    //        Auth.auth().currentUser.reauthenticate(with: credential) { (authResult, error) in
    //          guard error != nil else { return }
    //          // Apple user successfully re-authenticated.
    //          // ...
    //        }
    //    }
}
