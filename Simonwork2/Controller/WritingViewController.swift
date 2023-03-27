//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Foundation
import EmojiPicker

class WritingViewController: UIViewController {
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var textViewTextNumLabel: UILabel!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var letterBg: UIView!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    private lazy var emojiButton: UIButton = {
        let button = UIButton()
        button.setTitle("😃", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 70)
        button.addTarget(self, action: #selector(openEmojiPickerModule), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false // constraint와 충돌 방지
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeHolder: String = "제목을 입력해주세요"
        if titleTextView.text.isEmpty {
            titleTextView.text = placeHolder
            titleTextView.alpha = 0.5
        }
        titleTextView.delegate = self
        
        let placeholder: String = "작성하신 편지는 밤 사이 보낼게요."
        textViewTextNumLabel.text = "0 / 150자"
        if contentTextView.text.isEmpty {
            contentTextView.text = placeholder
            contentTextView.alpha = 0.5
        }
        contentTextView.delegate = self
        
        setupView()
        
        colorButton.layer.cornerRadius = 10
        setupColorButton(colorButton)
    }
    
    @IBAction func sendButtonPressed(_ sender: UIBarButtonItem) {

        UserDefaults.standard.set("none", forKey: "userName")
        UserDefaults.standard.set("none", forKey: "userEmail")
        
        if let title =
            titleTextView.text, let content = contentTextView.text {        db.collection("LetterData").addDocument(data: [
                "friendCode": "none", // 나의 친구코드
                "pairFriendCode": "none", // 상대방의 친구코드
                "id": "none", // 편지 아이디
                "title": title, // 편지 제목
                "content": content, // 편지 내용
                "updateTime": Date(),
                "receiveTime": Date(),
                "letterColor": "\(colorButton.titleLabel)",
                "emoji" : "none" // (이모지)
            ]) { (error) in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                    print("제목 또는 내용을 입력해주세요")
                } else {
                    print("작성하신 편지는 새벽 5시에 배달해드릴게요")
                    print("Successfully saved data.")

                    DispatchQueue.main.async {
                        self.contentTextView.text = ""
                    }
                }
            }
        }
    }
    
    @IBAction func setupColorButton(_ sender: UIButton) {
        let colorDics: Dictionary<String, UIColor> = ["Pupple": #colorLiteral(red: 0.6891200542, green: 0.6007183194, blue: 0.8024315238, alpha: 1), "Yellow": #colorLiteral(red: 0.9509314895, green: 0.9013540745, blue: 0, alpha: 1), "Tree": #colorLiteral(red: 0, green: 0.5727785826, blue: 0.324849844, alpha: 1), "Sky": #colorLiteral(red: 0.3175336123, green: 0.6844244003, blue: 0.9497999549, alpha: 1)]
        
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
            
            textViewTextNumLabel.text = "0 / 150자"
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {return false}
        
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        textViewTextNumLabel.text = "\(changedText.count) / 150자"
        return changedText.count <= 5 // 150자
    }
}
