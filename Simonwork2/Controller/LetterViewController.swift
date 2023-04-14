//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Firebase
import EmojiPicker

extension UITextView {
    func alignTextVerticallyInContainer() {
        var topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect;
        self.contentInset.top = topCorrect
    }
}

class LetterViewController: UIViewController {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var letterBg: UIView!
    @IBOutlet weak var emojiLabel: UILabel!
    
    let db = Firestore.firestore()
    
    var receivedTitleText: String?
    var receivedContentText: String?
    var receivedUpdateDate: Date?
    var receivedLetterColor : String?
    var receivedEmoji : String?
    
    // Create right UIBarButtonItem.
    lazy var rightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "수정", style: .plain, target: self, action: #selector(editButtonPressed))
        button.tag = 2
        
        return button
    }()

// Button event.
    @objc private func editButtonPressed(_ sender: Any) {
        if let button = sender as? UIBarButtonItem {
            switch button.tag {
            case 2:
                // Change the background color to red.
                self.view.backgroundColor = .red
                // 12시 이전에 수정 버튼 클릭 시 메시지가 수정되는 기능 구현 필요
            default:
                print("error")
            }
        }
    }
    
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        //f.timeStyle = .short
        return f
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = ""
        contentTextView.text = ""
        
        self.contentTextView.alignTextVerticallyInContainer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = receivedTitleText
        contentTextView.text = receivedContentText
        dateLabel.text = formatter.string(from: receivedUpdateDate ?? Date())
        letterBg.backgroundColor = UIColor(hex: receivedLetterColor!)
        
        //setupEmoji()
        emojiLabel.text = receivedEmoji!
//
//        print("titleTextView.text : \(titleTextView.text)")
//        print("contentTextView.text : \(contentTextView.text)")
//        print("dateLabel.text : \(dateLabel.text)")
//        print("letterBg.backgroundColor: \(letterBg.backgroundColor)")
//        print("emojiLabel.text: \(emojiLabel.text)")
    }
//    private func setupEmoji() {
//        view.backgroundColor = .white
//        view.addSubview(emojiLabel) // 필수: label을 view에 끌어다놓는 작업
//        
//        NSLayoutConstraint.activate([
//            emojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            emojiLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90), // 높이
//            emojiLabel.heightAnchor.constraint(equalToConstant: 80),
//            emojiLabel.widthAnchor.constraint(equalToConstant: 80),
//            emojiLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10), // 좌
//            emojiLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -240), // 우
//        ])
//    }
}
