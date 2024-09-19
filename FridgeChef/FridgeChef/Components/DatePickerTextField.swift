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
    
    var body: some View {
        HStack {
            // 将 DatePicker 和日历图标放在同一个 HStack 中
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()  // 隐藏标签
                .datePickerStyle(DefaultDatePickerStyle())  // 使用默认的 DatePicker 样式
                .environment(\.locale, Locale(identifier: "zh-Hant"))  // 设置为繁体中文

            Button(action: {
                self.showingDatePicker = true
            }) {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.clear)  // 设置背景为透明
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .sheet(isPresented: $showingDatePicker) {
            DatePicker("選擇日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())  // 使用图形化样式
                .environment(\.locale, Locale(identifier: "zh-Hant"))  // 设置为繁体中文
        }
    }
}

struct DatePickerTextField_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerTextField(date: .constant(Date()), label: "選擇日期")
    }
}
