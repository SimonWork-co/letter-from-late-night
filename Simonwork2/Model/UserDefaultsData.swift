//
//  UserDefaultsData.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/30.
//

import Foundation
import Firebase

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        let appGroupId = "group.Simonwork2"
        return UserDefaults(suiteName: appGroupId)!
    }
}

struct UserDefaultsData {
    
    var receivedData : User?
    
    struct Save {
        func userName(UserName: String) {
            UserDefaults.shared.set(UserName, forKey: "userName")
        }
        func userEmail(UserEmail: String) {
            UserDefaults.shared.set(UserEmail, forKey: "userEmail")
        }
        func friendCode(friendCode: String){
            UserDefaults.shared.set(friendCode, forKey: "friendCode")
        }
        func friendName(friendName: String){
            UserDefaults.shared.set(friendName, forKey: "friendName")
        }
        func uid(uid: String){
            UserDefaults.shared.set(uid, forKey: "ALetterFromLateNightUid")
        }
        func pairFriendCode(pairFriendCode: String){
            UserDefaults.shared.set(pairFriendCode, forKey: "pairFriendCode")
        }
        func signupTime(signupTime: Date){
            UserDefaults.shared.set(signupTime, forKey: "signupTime")
        }
    }
}
