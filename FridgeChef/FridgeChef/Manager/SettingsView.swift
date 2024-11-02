//
//  SettingsView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/7.
//

// todo: make button to change language
import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguage") var selectedLanguage: String = "zh"

    var body: some View {
        VStack {
            Text("Select Language")
            Picker(selection: $selectedLanguage, label: Text("Language")) {
                Text("English").tag("en")
                Text("Chinese").tag("zh")
            }
            .pickerStyle(SegmentedPickerStyle()) 
        }
        .padding()
    }
}

