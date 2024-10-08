//
//  DatePickerTextField.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//
//import SwiftUI
//
//struct DatePickerTextField: View {
//    @Binding var date: Date
//    var label: String
//
//    @State private var showingDatePicker = false
//
//    var dateFormatter: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd"
//        formatter.locale = Locale(identifier: "zh_Hant")  // 設置為繁體中文語系
//        return formatter
//    }
//
//    var body: some View {
//        // 使用 HStack 對齊 TextField 和按鈕
//        HStack {
//            TextField(label, text: Binding(
//                get: { dateFormatter.string(from: date) },
//                set: { _ in }  // 不允許 TextField 直接修改日期
//            ))
//            .disabled(true)
//            .padding()
//            .foregroundColor(.black)
//            .background(Color.clear)
//            .cornerRadius(5)
//            .frame(maxWidth: .infinity)  // 確保 TextField 填滿可用空間
//
//            Button(action: {
//                self.showingDatePicker = true  // 觸發顯示 DatePicker
//            }) {
//                Image(systemName: "calendar.badge.plus")
//                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//            }
//            .padding(.trailing, 5)  // 微調按鈕的右內邊距
//        }
//        // 移除內部的 .padding(.horizontal)，由外部管理間距
//        .sheet(isPresented: $showingDatePicker) {
//            VStack {
//                DatePicker(
//                    "選擇日期",
//                    selection: $date,
//                    displayedComponents: .date
//                )
//                .datePickerStyle(GraphicalDatePickerStyle())
//                .padding()
//
//                Button("Save") {
//                    self.showingDatePicker = false
//                }
//                .font(.headline)
//                .padding()
//                .frame(width: 300)
//                .background(Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//            }
//        }
//    }
//}
//
//struct DatePickerTextField_Previews: PreviewProvider {
//    static var previews: some View {
//        DatePickerTextField(date: .constant(Date()), label: "Choose a Date")
//            .previewLayout(.sizeThatFits)
//            .padding()
//    }
//}

import SwiftUI
import Foundation

struct DatePickerTextField: View {
    @Binding var date: Date
    var label: String
    
    @State private var showingDatePicker = false
    
    var body: some View {
        HStack {
            // 将 DatePicker 和日历图标放在同一个 HStack 中
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()  // 隐藏标签
                .datePickerStyle(DefaultDatePickerStyle())
                .font(.custom("ArialRoundedMTBold", size: 18))
                .environment(\.locale, Locale(identifier: "en-US"))  // 设置为繁体中文
            
            Button(action: {
                self.showingDatePicker = true
            }) {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
            }
        }
        .padding()
        .background(Color.clear)  // 设置背景为透明
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingDatePicker) {
            VStack{
                DatePicker("Choose a date!", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "en-US"))
                
                Button("Save") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showingDatePicker = false
                        
                    }
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .foregroundColor(.white)
                .font(.custom("ArialRoundedMTBold", size: 18))
                .cornerRadius(8)
            }
        }
    }
}

struct DatePickerTextField_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerTextField(date: .constant(Date()), label: "選擇日期")
    }
}
//
//.sheet(isPresented: $showingDatePicker) {
//    VStack {
//        DatePicker(
//            "Choose a date!",
//            selection: $date,
//            displayedComponents: .date
//        )
//        .datePickerStyle(GraphicalDatePickerStyle())
//        .font(.custom("ArialRoundedMTBold", size: 18))
//        .padding()
//
//        Button("Save") {
//            self.showingDatePicker = false
//        }
//        .padding()
//        .frame(maxWidth: 300)
//        .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//        .foregroundColor(.white)
//        .font(.custom("ArialRoundedMTBold", size: 18))
//        .cornerRadius(8)
//    }
//}
//}
//}
