//
//  WritingViewController.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/09.
//

import UIKit
import Foundation

class WritingViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewTextNumLabel: UILabel!
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
}
