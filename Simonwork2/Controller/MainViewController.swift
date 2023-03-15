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
    
    @IBOutlet weak var settingButton: UIBarButtonItem!
    @IBOutlet weak var dayCountingLabel: UILabel!
    @IBOutlet weak var todayDateLabel: UILabel!
    @IBOutlet weak var letterSendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
    }
    
    @IBAction func profileButton(_ sender: UIBarButtonItem) {
        //GIDSignIn.sharedInstance.signOut()
        print("worked!")
        navigationController?.popToRootViewController(animated: true)
    }
}

