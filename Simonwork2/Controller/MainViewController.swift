//
//  ViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/08.
//

import UIKit
import Firebase
import GoogleSignIn

class MainViewController: UIViewController {
    
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var dayCountingLabel: UILabel!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var letterSendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            print("로그아웃 성공")
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func profileButton(_ sender: UIBarButtonItem) {
        //GIDSignIn.sharedInstance.signOut()
        print("worked!")
        navigationController?.popToRootViewController(animated: true)
        
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            print("로그아웃 성공")
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func settingButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "mainToSetting", sender: self)
    }

}

