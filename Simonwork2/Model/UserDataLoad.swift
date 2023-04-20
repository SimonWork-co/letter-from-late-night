//
//  ServerData.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/20.
//

import Foundation
import Firebase

class UserDataLoad: UIViewController {
    let db = Firestore.firestore()
    
    
    func loadUserData() {
        let currentUserUid = Auth.auth().currentUser?.uid ?? ""
        db.collection("UserData").document(currentUserUid).getDocument { (documentSnapshot, error) in
            if let document = documentSnapshot, document.exists {
                if let data = document.data() {
                    let UserName = data["signupTime"] as? String
                    let UserEmail = data["userEmail"] as? String
                    
                }
            }
        }
    }
}
