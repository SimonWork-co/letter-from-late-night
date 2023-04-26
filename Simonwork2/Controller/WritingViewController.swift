//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Foundation
import EmojiPicker
import GoogleMobileAds

extension UIColor { // 색상의 hexcode 추출하는 extension
    func hexColorExtract(BackgroundColor: UIView) -> String {
        
        let backgroundColor = BackgroundColor.backgroundColor
        // Convert the UIColor object to its RGB components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        backgroundColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Format the RGB components as a hexadecimal string
        let hexColor = String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
        print("The hexadecimal color value of the view's background color is #\(hexColor).")
        return hexColor
    }
    
    convenience init?(hex: String) {
        //let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        let red, green, blue: CGFloat
        switch hex.count {
        case 6:
            red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        case 8:
            red = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            green = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
        default:
            return nil
        }
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

class WritingViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var textViewTextNumLabel: UILabel!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var letterBg: UIView!
    
    var textViewText : String = ""
    
    private lazy var emojiButton: UIButton = {
        let button = UIButton()
        button.setTitle("😃", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 70)
        button.addTarget(self, action: #selector(openEmojiPickerModule), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false // constraint와 충돌 방지
        return button
    }()
    
    // Create right UIBarButtonItem.
    lazy var rightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "보내기", style: .plain, target: self, action: #selector(sendButtonPressed))
        button.tag = 2
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.black]
        navigationBar.title = "밤편지 작성"
        navigationBar.rightBarButtonItem = self.rightButton
        
        titleTextField.borderStyle = .none
        titleTextField.delegate = self
        
        let contentPlaceholder: String = "작성하신 편지는 밤 사이 보낼게요."
        textViewTextNumLabel.text = "0 / 100"
        if contentTextView.text.isEmpty {
            contentTextView.text = contentPlaceholder
            contentTextView.alpha = 0.5
        }
        contentTextView.delegate = self
        setupView()
        
        colorButton.layer.cornerRadius = 10
        setupColorButton(colorButton)
        
        // 배너 광고 설정
        setupBannerViewToBottom()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func sendButtonPressed(_ sender: UIBarButtonItem) {
        let sheet0 = UIAlertController(title: "편지를 보낼까요?", message: "편지를 보내면 수정할 수 없어요", preferredStyle: .alert)
        sheet0.addAction(UIAlertAction(title: "취소", style: .destructive, handler: { _ in
            print("취소 클릭")
        }))
        sheet0.addAction(UIAlertAction(title: "확인", style: .cancel, handler: { _ in
            print("확인 클릭")
            self.sendLetterToDB(content: self.textViewText)
        }))
        self.present(sheet0, animated: true) {
        }
    }
    
    func sendLetterToDB(content: String!){
        let userUid = UserDefaults.shared.string(forKey: "ALetterFromLateNightUid")!
        let userFriendCode : String = UserDefaults.shared.object(forKey: "friendCode") as! String
        let userName : String = UserDefaults.shared.object(forKey: "userName") as! String
        let userPairFriendCode : String = UserDefaults.shared.object(forKey: "pairFriendCode") as! String
        
        if let title = titleTextField.text, let content = content {
            print("title: \(title)")
            print("content: \(content)")
            
            var titleCount : Int = 0
            var contentCount : Int = 0
            
            if title == "제목을 입력해주세요" {
                titleCount = 0
            } else if title == "" {
                titleCount = 0
            } else if content == "작성하신 편지는 밤 사이 보낼게요." {
                contentCount = 0
            } else if content == "" {
                contentCount = 0
            } else {
                titleCount = 1
                contentCount = 1
            }
            print("titleCount + contentCount = \(titleCount + contentCount)")
            if titleCount + contentCount == 0 {
                unableToSendLetter()
            } else if titleCount + contentCount == 1 {
                unableToSendLetter()
            } else if titleCount + contentCount == 2 {
                
                guard let hexColor = letterBg.backgroundColor?.hexColorExtract(BackgroundColor: letterBg) else {return}
                print(hexColor)
                
                let updateTime = Date()
                db.collection("LetterData").addDocument(data: [
                    "sender": userFriendCode, // 나의 친구코드
                    "senderName": userName,
                    "senderuid": userUid,
                    "receiver": userPairFriendCode, // 상대방의 친구코드
                    "id": "none", // 편지 아이디
                    "title": title, // 편지 제목
                    "content": content, // 편지 내용
                    "updateTime": updateTime,
                    "receiveTime": Date(),
                    "letterColor": hexColor,
                    "emoji" : emojiButton.titleLabel?.text // (이모지)
                ]) { (error) in
                    if let e = error {
                        print("There was an issue saving data to firestore, \(e)")
                    } else {
                        
                        db.collection("UserData").document(userUid).updateData([
                            "todayLetterTitle" : title,
                            "todayLetterContent" : content,
                            "todayLetterUpdateTime" : updateTime,
                        ]) { error in
                            if let error = error {
                                print("Error: \(error.localizedDescription)")
                            } else {
                                print("Field added successfully")
                            }
                        }
                        
                        // 오늘 편지를 보냈는지 확인하기 위해 userDefaults를 활용 "todayLetterUpdateTime"
                        UserDefaults.shared.setValue(title, forKey: "todayLetterTitle")
                        UserDefaults.shared.setValue(content, forKey: "todayLetterContent")
                        UserDefaults.shared.setValue(updateTime, forKey: "todayLetterUpdateTime")
                        
                        DispatchQueue.main.async { // '보내기' 이후 title, content 내용 초기화
                            self.titleTextField.text = ""
                            self.contentTextView.text = ""
                        }
                        
                        let sheet1 = UIAlertController(title: "작성 완료!", message: "작성하신 편지는 새벽에 배달해드릴게요", preferredStyle: .alert)
                        sheet1.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                            print("yes 클릭")
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(sheet1, animated: true)
                        //self.dismiss(animated: true)
                        print("Successfully saved data.")
                    }
                }
            }
        }
    }
    
    private func unableToSendLetter(){
        let sheet2 = UIAlertController(title: "제목 또는 내용을 입력해주세요", message: "채워지지 않은 부분이 있어요", preferredStyle: .alert)
        sheet2.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            print("yes 클릭")
        }))
        self.present(sheet2, animated: true)
    }
    
    @IBAction func setupColorButton(_ sender: UIButton) {
        let colorDics: Dictionary<String, UIColor> = ["Pupple": #colorLiteral(red: 0.6891200542, green: 0.6007183194, blue: 0.8024315238, alpha: 1), "Yellow": #colorLiteral(red: 0.9509314895, green: 0.9013540745, blue: 0, alpha: 1), "Tree": #colorLiteral(red: 0, green: 0.5727785826, blue: 0.324849844, alpha: 1), "Sky": #colorLiteral(red: 0.2408812046, green: 0.6738553047, blue: 1, alpha: 1)]
        
        let popUpButtonClosure = { [self] (action: UIAction) in
            var userSelectedColor = self.colorButton.currentTitle!
            letterBg.backgroundColor = colorDics[userSelectedColor]
            print(userSelectedColor)
        }
        
        colorButton.menu = UIMenu(children: [
            UIAction(title: "Pupple", handler: popUpButtonClosure),
            UIAction(title: "Yellow", handler: popUpButtonClosure),
            UIAction(title: "Tree", handler: popUpButtonClosure),
            UIAction(title: "Sky", handler: popUpButtonClosure)
        ])
        colorButton.showsMenuAsPrimaryAction = true
    }
    
    private func setupView() {
        view.backgroundColor = .white
        view.addSubview(emojiButton) // 필수: label을 view에 끌어다놓는 작업
        
        NSLayoutConstraint.activate([
            emojiButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emojiButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90), // 높이
            emojiButton.heightAnchor.constraint(equalToConstant: 80),
            emojiButton.widthAnchor.constraint(equalToConstant: 80),
            emojiButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10), // 좌
            emojiButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -240), // 우
        ])
    }
    
    @objc private func openEmojiPickerModule(sender: UIButton) {
        let viewController = EmojiPickerViewController()
        viewController.sourceView = sender
        viewController.delegate = self
        
        // Optional parameters
        viewController.selectedEmojiCategoryTintColor = .systemRed
        viewController.arrowDirection = .up
        viewController.horizontalInset = 16
        viewController.isDismissedAfterChoosing = true
        viewController.customHeight = 300
        viewController.feedbackGeneratorStyle = .soft
        
        present(viewController, animated: true)
    }
}

extension WritingViewController: EmojiPickerDelegate {
    func didGetEmoji(emoji: String) {
        emojiButton.setTitle(emoji, for: .normal)
    }
}

extension WritingViewController: UITextViewDelegate{
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = nil
        textView.alpha = 1
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "작성하신 편지는 밤 사이 보낼게요."
            textView.alpha = 0.5
            
            textViewTextNumLabel.text = "0 / 150"
        } else {
            textViewText = textView.text
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}

        let changedText = currentText.replacingCharacters(in: stringRange, with: text)

        let charCount = countCharacters(changedText)

        if charCount <= 150 { // 150자 이하일 경우에만 텍스트 업데이트
            textViewTextNumLabel.text = "\(charCount) / 150"
            return true
        } else {
            return false // 150자 이상인 경우 텍스트 업데이트 및 입력 막기
        }
    }
    
}

extension WritingViewController: UITextFieldDelegate {
    
    func countCharacters(_ text: String) -> Int {
        let charCount = text.utf16.count // String의 utf16 속성을 이용하여 글자 수를 세어줌
        return charCount
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        
        let changedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        let charCount = countCharacters(changedText)
        
        if charCount <= 25 { // 25자 이하일 경우에만 텍스트 업데이트
            return true
        } else {
            return false // 25자 이상인 경우 텍스트 업데이트 및 입력 막기
        }
    }
}
