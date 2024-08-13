//
//  SceneDelegate.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/08.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UITextFieldDelegate {
    
    var window: UIWindow?
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    var backgroundView: UIView?
    var imageView: UIImageView?
    
    static let lockStatusChangedNotification = Notification.Name("lockStatusChangedNotification")
    
    var isLocked: Bool = false {
        
        willSet {
            if newValue != isLocked {
                // 상태가 변경될 때만 업데이트
                NotificationCenter.default.post(name: SceneDelegate.lockStatusChangedNotification, object: nil)
            }
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        updateLockStatus()
        
        // 블러 효과 제거
        if isLocked {
            
            requestPasswordUnlock()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
       
        // 백그라운드 뷰 추가
        if isLocked {
            backgroundView = UIView(frame: window?.bounds ?? CGRect.zero)
            backgroundView?.backgroundColor = UIColor.white
            
            // 이미지 뷰 추가
            let image = UIImage(named: "launchScreen")
            imageView = UIImageView(image: image)
            imageView?.contentMode = .center
            imageView?.center = backgroundView?.center ?? CGPoint.zero
            imageView?.frame = backgroundView?.bounds ?? CGRect.zero
            
            if let finalBackgroundView = backgroundView, let imageView = imageView {
                imageView.center = CGPoint(x: finalBackgroundView.center.x, y: finalBackgroundView.center.y - 30)
                
                finalBackgroundView.addSubview(imageView)
                window?.addSubview(finalBackgroundView)
            }
        }

    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        print("SCENEDIDENTERBACKGROUND 진입!!")
        appDelegate.scheduleAppRefresh()
        appDelegate.scheduleProcessingTaskIfNeeded()
    }
    
    func updateLockStatus() {
        let screenLockPW = UserDefaults.shared.string(forKey: "screenLockPW")
        print("screenLockPW: ", screenLockPW)
        let shouldLock = screenLockPW != nil
        print("shouldLock: ", shouldLock)
        if shouldLock != isLocked {
            // 상태가 변경되어야 할 경우에만 업데이트
            isLocked = shouldLock
        }
    }


    
    func toggleLockStatus() {
        isLocked.toggle()

        NotificationCenter.default.post(name: SceneDelegate.lockStatusChangedNotification, object: nil)
    }
    
    @objc func lockPWAlert(message: String?, isChangingPWorLock: Bool, wCancel: Bool, completion: ((Bool) -> Void)? = nil) {
        
        guard let topController = window?.topViewController() else {
            return
        }
        
        let alertController = UIAlertController(title: "비밀번호 4자리를 입력해주세요", message: message, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "4자리 숫자를 입력해주세요"
            textField.keyboardType = .numberPad
            textField.delegate = self
        }
        
        let confirmAction = UIAlertAction(title: "완료", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first else {
                completion?(false)
                return
            }
            let inputText = textField.text ?? ""
            self?.handleInput(inputText, isChangingPWorLock: isChangingPWorLock) { success in
                completion?(success)
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completion?(false)
        }
        
        alertController.addAction(confirmAction)
        if wCancel {
            let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
                completion?(false)
            }
            alertController.addAction(cancelAction)
        }
        
        topController.present(alertController, animated: true, completion: nil)
    }
    
    private func handleInput(_ input: String, isChangingPWorLock: Bool, completion: ((Bool) -> Void)? = nil) {
        // 입력된 텍스트가 4자리 정수인지 검사
        if input.count == 4 {
            
            let previousPW = UserDefaults.shared.string(forKey: "screenLockPW")
            
            if previousPW == nil || previousPW == input {
                UserDefaults.shared.set(input, forKey: "screenLockPW")
                
                if isChangingPWorLock {
                    alert(title: "비밀번호가 설정되었습니다", message: "비밀번호 분실 시,\n앱을 삭제하고 다시 재설치해야합니다.", actionTitle: "확인")
                } 
//                else {
//                    alert(title: "편지함 잠금이 해제되었습니다", message: "잠금을 원한다면 다시 비밀번호를 설정해주세요", actionTitle: "확인")
//                }
                
                completion?(true)
            } else {
                alert(title: "비밀번호가 일치하지 않습니다", message: "다시 비밀번호를 입력해주세요", actionTitle: "확인")
                completion?(false)  // 실패로 클로저 호출
            }
        } else {
            alert(title: "유효한 비밀번호가 아닙니다", message: "4자리의 정수를 입력해주세요", actionTitle: "확인")
            completion?(false)  // 실패로 클로저 호출
        }
    }
    
    
    private func requestPasswordUnlock(attemptCount: Int = 0) {
        guard attemptCount < 5 else {
            alert(title: "\(attemptCount)회 실패", message: "비밀번호가 5회 일치하지 않는 경우, 앱을 재시작해주세요", actionTitle: "확인")
            return
        }

        lockPWAlert(message: "비밀번호를 입력해주세요", isChangingPWorLock: false, wCancel: false) { [weak self] success in
            if success {
                self?.backgroundView?.removeFromSuperview()
                self?.imageView?.removeFromSuperview()
            } else {
                // 실패한 경우 다시 시도
                self?.requestPasswordUnlock(attemptCount: attemptCount + 1)
            }
        }
    }
    
}

extension SceneDelegate {
    func alert(title: String, message: String, actionTitle: String) {
        guard let topController = window?.topViewController() else {
            print("Top ViewController가 존재하지 않습니다.")
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default)
        alertController.addAction(action)
        topController.present(alertController, animated: true)
    }
}

extension UIWindow {
    func topViewController() -> UIViewController? {
        var topController = rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }
}

