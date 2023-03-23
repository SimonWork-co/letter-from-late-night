//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Foundation
<<<<<<< HEAD
import EmojiPicker
=======
>>>>>>> ecb0760 (feat: WritingViewController)

class WritingViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewTextNumLabel: UILabel!
<<<<<<< HEAD
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var letterBg: UIView!
    
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
        let placeholder: String = "작성하신 편지는 밤 사이 보낼게요."
        
        textViewTextNumLabel.text = "0 / 150자"
        if textView.text.isEmpty {
            textView.text = placeholder
            textView.alpha = 0.5
        }
        textView.delegate = self
        
        setupView()
        
        colorButton.layer.cornerRadius = 10
        setupColorButton()
    }
    
    func setupColorButton() {
        let popUpButtonClosure = { [self] (action: UIAction) in
            let result = self.colorButton.currentTitle!
            print(result)
            // 해결 필요~~~ 색 안바뀜. 배열 하나 만들어서 바꿔줘야할듯
            letterBg.backgroundColor = UIColor(named: result)
        }
        
        colorButton.menu = UIMenu(children: [
            UIAction(title: "Pupple", handler: popUpButtonClosure),
            UIAction(title: "Yellow", handler: popUpButtonClosure),
            UIAction(title: "Olive", handler: popUpButtonClosure),
            UIAction(title: "Skyblue", handler: popUpButtonClosure)
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
=======
    @IBOutlet weak var emojiLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(emojiLabelTapEvent(_:)))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        
        if textView.text.isEmpty {
            textView.text = "작성하신 편지는 밤 사이 보낼게요."
            textView.alpha = 0.5
        }
        textView.delegate = self
        textViewTextNumLabel.text = "0 / 150자"
    }
    
    @objc func emojiLabelTapEvent(_ gesture: UITapGestureRecognizer) {
           print("이모티콘 클릭")
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
>>>>>>> ecb0760 (feat: WritingViewController)
}
