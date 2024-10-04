//
//  DatePickerTextField.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI
import Foundation

struct DatePickerTextField: View {
    @Binding var date: Date
    var label: String
    
    @State private var showingDatePicker = false
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "en-US")  // TODO 設置為繁體中文語系zh_Hant
        return formatter
    }
    
    var body: some View {
        // 使用HStack對齊TextField和按鈕
        HStack {
            TextField(label, text: Binding(
                get: { dateFormatter.string(from: date) },
                set: { _ in }  // 不允許TextField直接修改日期
            ))
            .disabled(true)
            .padding()
            .foregroundColor(.black)
            .background(Color.clear)
            .cornerRadius(5)
            .frame(maxWidth: .infinity)  // 確保TextField填滿可用空間

            Button(action: {
                self.showingDatePicker = true  // 觸發顯示DatePicker
            }) {
                Image(systemName: "calendar.badge.plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))          
            }
            .padding(.trailing, 5)  // 微調按鈕的右內邊距
        }
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal)  // 調整整個HStack的水平內邊距，以與其他界面元件對齊
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker(
                    "選擇日期",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Button("Save") {
                    self.showingDatePicker = false
                }
                .font(.headline)
                .padding()
                .frame(width: 300)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

struct DatePickerTextField_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerTextField(date: .constant(Date()), label: "Choose a Date")
    }
}


//import SwiftUI
//import Foundation
//
//struct DatePickerTextField: View {
//    @Binding var date: Date
//    var label: String
//    
//    @State private var showingDatePicker = false
//    
//    var body: some View {
//        HStack {
//            // 将 DatePicker 和日历图标放在同一个 HStack 中
//            DatePicker("", selection: $date, displayedComponents: .date)
//                .labelsHidden()  // 隐藏标签
//                .datePickerStyle(DefaultDatePickerStyle())  // 使用默认的 DatePicker 样式
//                .environment(\.locale, Locale(identifier: "zh-Hant"))  // 设置为繁体中文
//            
//            Button(action: {
//                self.showingDatePicker = true
//            }) {
//                Image(systemName: "calendar.badge.plus")
//                    .foregroundColor(.orange)
//            }
//        }
//        .padding()
//        .background(Color.clear)  // 设置背景为透明
//        .overlay(
//            RoundedRectangle(cornerRadius: 5)
//                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//        )
//        .sheet(isPresented: $showingDatePicker) {
//            VStack{
//                DatePicker("選擇日期", selection: $date, displayedComponents: .date)
//                    .datePickerStyle(GraphicalDatePickerStyle())
//                    .environment(\.locale, Locale(identifier: "zh-Hant"))
//                
//                Button("確認") {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        self.showingDatePicker = false
//                        
//                    }
//                }
//                    .font(.headline)
//                    .padding()
//                    .frame(maxWidth: 300)
//                    .background(Color.orange)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                }
//            }
//        }
//    }
//    
//    struct DatePickerTextField_Previews: PreviewProvider {
//        static var previews: some View {
//            DatePickerTextField(date: .constant(Date()), label: "選擇日期")
//        }
//    }
