//
//  LetterWidget.swift
//  LetterWidget
//
//  Created by daelee on 2023/04/01.
//

//https://zeddios.tistory.com/1088

import Foundation
import WidgetKit
import SwiftUI
import UIKit

extension UserDefaults {
    static var shared: UserDefaults {
        let appGroupId = "group.Simonwork2"
        return UserDefaults(suiteName: appGroupId)!
    }
}

let dateFormatterFile = DateFormatterFile()

let setTitle = UserDefaults.shared.string(forKey: "latestTitle")!
let setContent = UserDefaults.shared.string(forKey: "latestContent")!
let setUpdateDate = UserDefaults.shared.object(forKey: "latestUpdateDate") as! Date
let setLetterColor = UserDefaults.shared.string(forKey: "latestLetterColor")!
let setEmoji = UserDefaults.shared.string(forKey: "latestEmoji")!
let uicolor = UIColor(hex: setLetterColor)
let setSenderName = UserDefaults.shared.string(forKey: "latestSenderName")!

// 위젯을 업데이트 할 시기를 WidgetKit에 알리는 역할
struct Provider: TimelineProvider {
    // 위젯의 업데이트할 시기를 WidgetKit에 알려준다.
    // WidgetKit이 Provider에 업데이트 할 시간, TimeLine을 요청, 요청을 받은 Provider는 TimeLine을 WidgetKit에 제공
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), title: "Placeholder Title", content: "Placeholder Content", emoji: "😃", sender: "Sender")
    }
    // 데이터를 가져와서 표출해주는 함수
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry: SimpleEntry
        
        switch context.family {
        case .systemSmall:
            entry = SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")
        case .systemMedium:
            entry = SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "바쁘더라도 끼니 굶지 말고\n몸 잘 챙겨 가면서 해\n오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")
        case .systemLarge:
            entry = SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "바쁘더라도 끼니 굶지 말고\n몸 잘 챙겨가면서 해\n\n어제 만났을 때 보니깐 너무 피곤해보였어\n\n점심시간에 눈도 잠깐 붙이면서 쉬엄쉬엄해~\n\n오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")
        @unknown default:
            entry = SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")
        }
        
        completion(entry)
    }
    // 타임라인 설정 관련 함수(홈에 있는 위젯을 언제 업데이트 시킬 것인지 구현)
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) { //처음에 WidgetKit은 Provider에게 TimeLine을 요청하며, 이 메소드를 호출.
        
        var entries: [SimpleEntry]
        
        switch context.family {
        case .systemSmall:
            entries = [SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")]
        case .systemMedium:
            entries = [SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "바쁘더라도 끼니 굶지 말고\n몸 잘 챙겨 가면서 해\n오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")]
        case .systemLarge:
            entries = [SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "바쁘더라도 끼니 굶지 말고\n몸 잘 챙겨가면서 해\n\n어제 만났을 때 보니깐 너무 피곤해보였어\n\n점심시간에 눈도 잠깐 붙이면서 쉬엄쉬엄해~\n\n오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")]
        @unknown default:
            entries = [SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹은거지?", content: "오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")]
        }
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let set5am = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 5), matchingPolicy: .nextTime)! // Schedule the task to start at 5:00 AM
        
        for hourOffset in 0 ..< 30 {
            // 1, 2, ... 30 분 뒤 enrty값으로 업데이트
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset, to: set5am)!
            let entry = SimpleEntry(date: setUpdateDate, title: setTitle, content: setContent, emoji: setEmoji, sender: setSenderName)
            entries = []
            entries.append(entry)
        }
        // 타임라인을 새로 다시 불러옴
        let timeline = Timeline(entries: entries, policy: .atEnd)
        // atEnd: 타임라인의 마지막 날짜가 지난 후 WidgetKit이 새 타임라인을 요청하도록 지정하는 정책
        completion(timeline)
    }
}

// TimelineEntry: 위젯을 표시할 date, data에 표시할 데이터를 나타냄
struct SimpleEntry: TimelineEntry {
    // 위젯을 표시할 날짜를 지정, 위젯 콘텐츠의 현재 관련성 이라고 해석됩니다. 기본적으로 TimelineEntry 는 기본적으로 프로토콜이고 date 프로퍼티를 필수로 요구합니다.
    // "TimelineEntry는 date 라는 필수 프로퍼티를 가지는 프로토콜이고 이 date는 위젯을 업데이트하는 시간을 담고 있다."
    let date: Date
    let title: String
    let content: String
    let emoji: String
    let sender: String
}

struct LetterWidgetEntryView : View { // 위젯의 내용물을 보여주는 SwiftUI View
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: Provider.Entry
    
    @ViewBuilder
    var body: some View {
        switch self.family {
        case .systemSmall:
            VStack {
                Text(entry.title)
                    .font(.custom("NanumMyeongjoBold", size: 11))
                    .foregroundColor(.black)
                    .padding(0.1)
                Spacer()
                Text(entry.content)
                    .font(.custom("NanumMyeongjo", size: 10))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                Spacer()
            }.padding()
        case .systemMedium :
            VStack {
                HStack{
                    Text(entry.emoji)
                        .font(.custom("NanumMyeongjo", size: 25))
                    Text(entry.title)
                        .font(.custom("NanumMyeongjoBold", size: 15))
                        .foregroundColor(.black)
                    Spacer()
                }.padding(1)
                Spacer()
                Text(entry.content)
                    .font(.custom("NanumMyeongjo", size: 12))
                    .foregroundColor(.black)
                    .padding(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                HStack(alignment: .bottom){
                    Spacer()
                    Text(entry.sender)
                        .font(.custom("NanumMyeongjoBold", size: 10))
                        .foregroundColor(.black)
                    Text(dateFormatterFile.dateFormatting(date: entry.date)) // entry.date를 string으로 변환
                        .font(.custom("NanumMyeongjo", size: 10))
                        .foregroundColor(.black)
                }
            }
            .padding()
        case .systemLarge :
            VStack {
                HStack{
                    Text(entry.emoji)
                        .font(.custom("NanumMyeongjoExtraBold", size: 40))
                    Text(entry.title)
                        .font(.custom("NanumMyeongjoBold", size: 20))
                        .foregroundColor(.black)
                }.padding(3)
                Spacer()
                Text(entry.content)
                    .font(.custom("NanumMyeongjo", size: 17))
                    .foregroundColor(.black)
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                HStack(alignment: .bottom){
                    Spacer()
                    Text(entry.sender)
                        .font(.custom("NanumMyeongjoBold", size: 15))
                        .foregroundColor(.black)
                    Text(dateFormatterFile.dateFormatting(date: entry.date)) // entry.date를 string으로 변환
                        .font(.custom("NanumMyeongjo", size: 15))
                        .foregroundColor(.black)
                }
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
        StaticConfiguration(
            kind: kind,
            // 위젯 ID.
            provider: Provider()
            // 위젯 생성자.
            // 위젯을 새로고침할 타임라인을 결정하고 생성하는 객체입니다. 위젯 업데이트를 위한 시간을 지정해주면 알아서 그 시간에 맞춰서 업데이트를 시켜준다고 합니다.
        ) { entry in LetterWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.init(uiColor: uicolor!)) // 위젯의 배경색상 가져오기
            // 이 클로저에는 widget을 렌더링하는 SwiftUI View 코드가 포함되어 있습니다. 그리고 TimelineEntry 매개변수를 전달하는데 예제에서는 SimpleEntry 를 전달하게 됩니다. 그리고 넘어온 데이터를 이용해서 View를 구성하면 됩니다.
        } // 위젯갤러리에 노출
        .configurationDisplayName("밤편지")
        // 위젯을 추가/편집 할 때 위젯에 표시되는 이름을 세팅하는 메소드입니다.
        .description("원하는 사이즈의 위젯을 선택해주세요")
        // 위젯을 추가/편집 할 때 위젯에 표시되는 설명 부분을 세팅하는 메소드입니다.
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // 위젯이 지원하는 크기를 설정할 수 있는 메소드입니다.
    }
}

struct LetterWidget_Previews: PreviewProvider {
    static var previews: some View {
        
        let entry = SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹었어?", content: "오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람")
        
        Group {
            LetterWidgetEntryView(entry: SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹었어?", content: "오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람"))
                .background(Color.init(uiColor: UIColor(hex: "F7D88C")!))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            LetterWidgetEntryView(entry: SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹었어?", content: "바쁘더라도 끼니 굶지 말고\n몸 잘 챙겨 가면서 해\n오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람"))
                .background(Color.init(uiColor: UIColor(hex: "F7D88C")!))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            LetterWidgetEntryView(entry: SimpleEntry(date: Date(), title: "밥은 잘 챙겨먹었어?", content: "바쁘더라도 끼니 굶지 말고\n몸 잘 챙겨가면서 해\n\n어제 만났을 때 보니깐 너무 피곤해보였어\n\n점심시간에 눈도 잠깐 붙이면서 쉬엄쉬엄해~\n\n오늘 하루도 화이팅!", emoji: "😃", sender: "하나뿐인 사람"))
                .background(Color.init(uiColor: UIColor(hex: "F7D88C")!))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
