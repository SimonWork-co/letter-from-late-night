//
//  LetterWidgetBundle.swift
//  LetterWidget
//
//  Created by daelee on 2023/04/01.
//

import WidgetKit
import SwiftUI

@main
struct LetterWidgetBundle: WidgetBundle {
    var body: some Widget {
        LetterWidget()
        LetterWidgetLiveActivity()
    }
}
