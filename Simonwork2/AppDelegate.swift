//
//  AppDelegate.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/08.
//
//http://yoonbumtae.com/?p=5329 (Swift(스위프트): 백그라운드 작업 (Background Tasks))
//https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background/using_background_tasks_to_update_your_app

import UIKit
import Firebase
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore
import BackgroundTasks
import CryptoKit
import WidgetKit
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // 1. didFinishLaunchingWithOptions: 앱이 종료되어 있는 경우 알림이 왔을 때
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // 앱 푸시 상태를 확인하는 함수
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkNotificationSetting),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        //registerBackgroundTasks()
        //1. 등록
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.simonwork.Simonwork2.refresh_badge", using: nil) { task in
            print("백그라운드 등록 진입")
            task.setTaskCompleted(success: true)
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.simonwork.Simonwork2.refresh_process", using: nil) { task in
            print("백그라운드 등록 진입")
            task.setTaskCompleted(success: true)
            self.handleProcessingTask(task: task as! BGProcessingTask)
        }
        //sleep(1)
        
        return true
    }
    
    //    func applicationDidEnterBackground(_ application: UIApplication) {
    //        scheduleAppRefresh()
    //        scheduleProcessingTaskIfNeeded()
    //    }
    
    @objc private func checkNotificationSetting() {
        UNUserNotificationCenter.current()
            .getNotificationSettings { permission in
                switch permission.authorizationStatus  {
                case .authorized:
                    print("푸시 수신 동의")
                case .denied:
                    print("푸시 수신 거부")
                    SendUserNotification().requestNotificationAuthorization()
                case .notDetermined:
                    print("한 번 허용 누른 경우")
                case .provisional:
                    print("푸시 수신 임시 중단")
                case .ephemeral:
                    // @available(iOS 14.0, *)
                    print("푸시 설정이 App Clip에 대해서만 부분적으로 동의한 경우")
                @unknown default:
                    print("Unknow Status")
                }
            }
    }
    
    //2. 스케줄링
    func scheduleAppRefresh() {
        print("백그라운드 스케줄링 진입")
        let request = BGAppRefreshTaskRequest(identifier: "com.simonwork.Simonwork2.refresh_badge")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15)
        //request.earliestBeginDate = Date(timeInterval: 15, since: Date())
        //request.earliestBeginDate = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 8), matchingPolicy: .nextTime) // Schedule the task to start at 8:00 AM
        
        do {
            try BGTaskScheduler.shared.submit(request)
            // Set a breakpoint in the code that executes after a successful call to submit(_:).
            // 브레이크 포인트 작성
        } catch {
            print("\(Date()): Could not schedule app refresh: \(error)")
        }
    }
    
    //2. 스케줄링
    func scheduleProcessingTaskIfNeeded() {
        print("백그라운드 스케줄링 진입")
        let request = BGProcessingTaskRequest(identifier: "com.simonwork.Simonwork2.refresh_process")
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15)
        //request.earliestBeginDate = Date(timeInterval: 15, since: Date())
        //request.earliestBeginDate = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 8), matchingPolicy: .nextTime) // Schedule the task to start at 8:00 AM
        
        do {
            try BGTaskScheduler.shared.submit(request)
            // Set a breakpoint in the code that executes after a successful call to submit(_:).
            // 브레이크 포인트 작성
        } catch {
            print("\(Date()): Could not schedule processing task: \(error)")
        }
    }
    // 3.실행&완료
    func handleAppRefresh(task: BGAppRefreshTask) {
        // 스케줄링 함수. 다음 동작 수행, 반복시 필요
        print("실행 완료 진입")
        scheduleAppRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        DispatchQueue.global(qos: .background).async {
            // 가벼운 백그라운드 작업 작성
            print("메시지 로드 진입")
            self.handleScheduledLoadMessages()
            task.setTaskCompleted(success: true)
            print("setTaskCompleted에 진입")
        }
    }
    // 3.실행&완료
    func handleProcessingTask(task: BGProcessingTask) {
        print("실행 완료 진입")
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        DispatchQueue.global(qos: .background).async {
            // 가벼운 백그라운드 작업 작성
            print("메시지 로드 진입")
            self.handleScheduledLoadMessages()
            task.setTaskCompleted(success: true)
            print("setTaskCompleted에 진입")
        }
        
    }
    
    @objc func handleScheduledLoadMessages() {
        // This method will be called when the scheduled time is reached
        DispatchQueue.main.async {
            let archiveVC = ArchiveViewController()
            archiveVC.archiveUpdate()
            
            //tableView?.reloadData()
            //tableView?.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: false)
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        do {
            try Auth.auth().useUserAccessGroup("sangmok Choi.group.Simonwork2")
        } catch let error as NSError {
            print("Error changing user access group: %@", error)
        }
        setupAndMigrateFirebaseAuth()
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
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainViewController = storyboard.instantiateViewController(identifier: "SignupViewController")
            mainViewController.modalPresentationStyle = .fullScreen
            NavigationController().show(mainViewController, sender: self)
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
    
    func setupAndMigrateFirebaseAuth() {
        let BuildEnvironmentAppGroup = "group.Simonwork2"
        guard Auth.auth().userAccessGroup != BuildEnvironmentAppGroup else { return }
        //for extension (widget) we want to share our auth status
        do {
            //get current user (so we can migrate later)
            let user = Auth.auth().currentUser
            //switch to using app group
            try Auth.auth().useUserAccessGroup(BuildEnvironmentAppGroup)
            //migrate current user
            if let user = user {
                Auth.auth().updateCurrentUser(user) { error in
                    if error == nil {
                        print ("Firebase Auth user migrated")
                    }
                }
            }
            
        } catch let error as NSError {
            print("error: \(error)")
        }
        
    }
    
}

