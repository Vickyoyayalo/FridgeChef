//
//  SettingsView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/7.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguage") var selectedLanguage: String = "zh" // Default is Chinese ("zh")

    var body: some View {
        VStack {
            Text("Select Language")
            Picker(selection: $selectedLanguage, label: Text("Language")) {
                Text("English").tag("en")
                Text("Chinese").tag("zh")
            }
            .pickerStyle(SegmentedPickerStyle()) // Optional style
        }
        .padding()
    }
}

