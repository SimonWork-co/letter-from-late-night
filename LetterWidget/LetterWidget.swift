//
//  LetterWidget.swift
//  LetterWidget
//
//  Created by daelee on 2023/04/01.
//

import WidgetKit
import SwiftUI

// 위젯을 업데이트 할 시기를 WidgetKit에 알리는 역할
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), title: "Placeholder Title", content: "Placeholder Content")
    }

    // 데이터를 가져와서 표출해주는 함수
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), title: "Snapshot Title", content: "Snapshot Content")
        completion(entry)
    }

    // 타임라인 설정 관련 함수(홈에 있는 위젯을 언제 업데이트 시킬 것인지 구현)
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            // 1, 2, ... 4 시간 뒤 enrty값으로 업데이트
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: Date(), title: "Timeline Title", content: "Timeline Content")
            entries.append(entry)
        }

        // 4시간 뒤에 타임라인을 새로 다시 불러옴
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

let sharedUserDefaults = UserDefaults(suiteName: "group.simon.work2")
let sharedData = sharedUserDefaults?.string(forKey: "mySharedData")

// TimelineEntry: 위젯을 표시할 date, data에 표시할 데이터를 나타냄
struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let content: String
}

struct LetterWidgetEntryView : View {
    @Environment(\.widgetFamily) var family: WidgetFamily
      var entry: Provider.Entry

    @ViewBuilder
    var body: some View {
    switch self.family {
        // ExtraLarge는 iPad의 위젯에만 표출
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            VStack {
                Text(entry.title)
                    .font(.headline)
                Text(entry.content)
                    .font(.subheadline)
            }
            .padding()
        default:
          Text("default")
        }
      }
}

struct LetterWidget: Widget {
    let kind: String = "LetterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, // 위젯 ID
                            provider: Provider() // 위젯 생성자
        ) {
            entry in
            // 위젯 뷰
            LetterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("밤편지")
        .description("150자는 Large 사이즈로 설정해주세요. 등등")
    }
}

struct LetterWidget_Previews: PreviewProvider {
    static var previews: some View {
        LetterWidgetEntryView(entry: SimpleEntry(date: Date(), title: "Preview Title", content: "Preview Content"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
