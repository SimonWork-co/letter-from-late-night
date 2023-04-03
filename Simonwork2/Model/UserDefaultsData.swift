//
//  UserDefaultsData.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/30.
//

import Foundation
import Firebase

struct UserDefaultsData {
    
    var receivedData : User?
    
    struct Save {
        func userName(UserName: String) {
            UserDefaults.standard.set("\(UserName)", forKey: "userName")
        }
        func userEmail(UserEmail: String) {
            UserDefaults.standard.set("\(UserEmail)", forKey: "userEmail")
        }
        func friendCode(friendCode: String){
            UserDefaults.standard.set("\(friendCode)", forKey: "friendCode")
        }
        func friendName(friendName: String){
            UserDefaults.standard.set("\(friendName)", forKey: "friendName")
        }
        func uid(uid: String){
            UserDefaults.standard.set("\(uid)", forKey: "ALetterFromLateNightUid")
        }
        func pairFriendCode(pairFriendCode: String){
            UserDefaults.standard.set("\(pairFriendCode)", forKey: "pairFriendCode")
        }
        func signupTime(signupTime: Date){
            UserDefaults.standard.set("\(signupTime)", forKey: "pairFriendCode")
        }
    }
    
//    struct Load {
//        func userName() -> String {
//            let userName : String = UserDefaults.standard.object(forKey: "userName") as! String
//            return userName
//        }
//        func userEmail() -> String {
//            let userEmail : String = UserDefaults.standard.object(forKey: "userEmail") as! String
//            return userEmail
//        }
//        func friendName() -> String {
//            let friendName : String = UserDefaults.standard.object(forKey: "friendName") as! String
//            return friendName
//        }
//        func friendCode() -> String {
//            let friendCode : String = UserDefaults.standard.object(forKey: "friendCode") as! String
//            return friendCode
//        }
//        func uid() -> String {
//            let uid : String = UserDefaults.standard.object(forKey: "ALetterFromLateNightUid") as! String
//            return uid
//        }
//        func pairFriendCode() -> String {
//            let pairFriendCode : String = UserDefaults.standard.object(forKey: "pairFriendCode") as! String
//            return pairFriendCode
//        }
//        func signupTime() -> Date {
//            let signupTime : Date = UserDefaults.standard.object(forKey: "signupTime") as! Date
//            return signupTime
//        }
//
//    }
}
