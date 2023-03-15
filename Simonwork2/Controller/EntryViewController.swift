//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import GoogleSignIn

class EntryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        checkAutoLogin()
    }
    
    func checkAutoLogin() {
        GIDSignIn.sharedInstance.restorePreviousSignIn()// 자동로그인
    }

//    @IBAction func loginButtonPressed(_ sender: UIButton) {
//    
//        performSegue(withIdentifier: "entryToLogin", sender: self)
//    }
    
}
