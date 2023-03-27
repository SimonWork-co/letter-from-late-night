//
//  LetterDataSource.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/10.
//

import UIKit
import Foundation

class LetterDataSource {
    let title: String
    let content: String
    var date: Date
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
        date = Date()
    }
}

extension LetterDataSource {
    static var data = [
        LetterDataSource(title: "밥은 잘 먹었어?", content: "아무말 아무말"),
        LetterDataSource(title: "밥은 잘 먹었어?", content: "아무말 아무말")
    ]
}
