//
//  LetterDataSource.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/03/10.
//

import UIKit

struct LetterDataSource {
    let title : String
    let date : String
}

extension LetterDataSource {
    static var data = [
        LetterDataSource(title: "밥은 잘 먹었어?", date: "2023.01.03"),
    ]
}
// 변수로 바꿔두기
