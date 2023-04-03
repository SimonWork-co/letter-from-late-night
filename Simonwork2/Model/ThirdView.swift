//
//  CustomizedCell.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/10.
//

import UIKit

class ThirdView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBOutlet weak var toSignupButton: UIButton!
    //toSignupButton.layer.cornerRadius = 10
    
    @IBAction func ToSignup(_ sender: UIButton) {
        
    }
}
