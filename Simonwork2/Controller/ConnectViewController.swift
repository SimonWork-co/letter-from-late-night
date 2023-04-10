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
        sendUserData(UserName: inputUserName, UserEmail: inputUserEmail)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //let userName : String = UserDefaults.standard.object(forKey: "userName") as! String
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        helloLabel.text = "안녕하세요! \(inputUserName)님"
        helloLabel.asColor(targetStringList: [inputUserName], color: .purple)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      navigationController?.setNavigationBarHidden(true, animated: true) // 뷰 컨트롤러가 사라질 때 나타내기
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "connectToConnectTyping", sender: nil)
    }
}
