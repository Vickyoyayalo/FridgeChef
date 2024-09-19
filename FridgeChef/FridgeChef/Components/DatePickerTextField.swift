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
            TextField(label, text: Binding(
                get: { DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none) },
                set: { _ in }
            ))
            .disabled(true)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .overlay(
                // 將日曆圖示作為 overlay 添加到 TextField
                Button(action: {
                    self.showingDatePicker = true
                }) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.orange)
                }
                .padding(.trailing, 10),
                alignment: .trailing
            )
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingDatePicker) {
            DatePicker("選擇日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color.white)
        }
    }
}

struct DatePickerTextField_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerTextField(date: .constant(Date()), label: "選擇日期")
    }
}
