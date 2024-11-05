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
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(DefaultDatePickerStyle())
                .font(.custom("ArialRoundedMTBold", size: 18))
                .environment(\.locale, Locale(identifier: "en-US"))
        }
        .padding()
        .contentShape(Rectangle())
        .background(Color.clear)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker("Choose a date!", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "en-US"))
                
                Button("Save") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showingDatePicker = false
                        
                    }
                }
                .padding()
                .frame(width: 100, height: 50)
                .contentShape(Rectangle())
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
        DatePickerTextField(date: .constant(Date()), label: "Choose Date!")
    }
}
