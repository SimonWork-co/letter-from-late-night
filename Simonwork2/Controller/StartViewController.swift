//
//  ConnectViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/23.
//

import UIKit

class StartViewController: UIViewController {
    
    let mainVC = MainViewController()
    
    @IBOutlet weak var helloLabel: UILabel!
    
    let userName : String = UserDefaults.shared.object(forKey: "userName") as! String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        helloLabel.text = "안녕하세요! \(userName)님"
        helloLabel.asColor(targetStringList: [userName], color: .black)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController의 view가 load됨")
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        // Main 화면으로 보내기
        performSegue(withIdentifier: "startToMain", sender: self)
//        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//        let mainViewController = storyboard.instantiateViewController(identifier: "MainViewController")
//        mainViewController.modalPresentationStyle = .fullScreen
//        self.navigationController?.show(mainViewController, sender: nil)
    }
}
