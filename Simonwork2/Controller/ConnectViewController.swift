//
//  ConnectViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/23.
//

import UIKit
import Firebase

class ConnectViewController: SignupViewController {
    //let userName = userDefaultsDataLoad.userName()
    
    @IBOutlet weak var helloLabel: UILabel!
    
    //let userName : String = UserDefaults.standard.object(forKey: "userName") as! String
    let data = UserDefaultsData().receivedData
    
    var inputUserName : String = ""
    var inputUserEmail : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        sendUserData(UserName: inputUserName, UserEmail: inputUserEmail)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //let userName : String = UserDefaults.standard.object(forKey: "userName") as! String
        
        super.viewWillAppear(animated)
        print("ViewController의 view가 Load됨")
        
        //helloLabel.text = "안녕하세요! \(userName)님"
        //helloLabel.asColor(targetStringList: [userName], color: .black)
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "connectToConnectTyping", sender: nil)
    }
}
