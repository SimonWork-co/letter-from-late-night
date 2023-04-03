//
//  AppDelegate.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/08.
//

import UIKit
import Firebase
//import FirebaseCore
//import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // 1. didFinishLaunchingWithOptions: 앱이 종료되어 있는 경우 알림이 왔을 때
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        let db = Firestore.firestore()
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // 2. didReceive: 백그라운드인 경우 & 사용자가 푸시를 클릭한 경우
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
        let application = UIApplication.shared
                
            //앱이 켜져있는 상태에서 푸쉬 알림을 눌렀을 때
            if application.applicationState == .active {
                print("푸쉬알림 탭(앱 켜져있음)")
                
            
            }
            
            //앱이 꺼져있는 상태에서 푸쉬 알림을 눌렀을 때
            if application.applicationState == .inactive {
//                if response.notification.request.content.title == "밤편지" {
//                }
                print("푸쉬알림 탭(앱 꺼져있음)")
            }
        
        completionHandler()
    }
    
    // 3. willPresent: 앱이 실행 중인 경우 (foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) { // ios14에서 .alert가 사라졌기 때문에 list, banner를 함께 넣어줘야함
            completionHandler([.alert, .list,.sound,.banner])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        var handled: Bool
        
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        // Handle other custom URL types.
        
        // If not handled by this app, return false.
        return false
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

