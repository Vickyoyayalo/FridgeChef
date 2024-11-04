//
//  SearchAndFilterView.swift
//  food
//
//  Created by Vickyhereiam on 2024/10/05.
//

import SwiftUI

struct SearchAndFilterView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 16) {
            HStack {
                
                if let searchImage = UIImage(named: "search") {
                    Image(uiImage: searchImage)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                
                TextField("Search my favorites", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(.lightGray).opacity(0.7))
            .cornerRadius(8)
        }
    }
}

