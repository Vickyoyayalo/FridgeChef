//
//  PlaceholderTextEditor.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//
import SwiftUI
import Foundation

struct PlaceholderTextEditor: View {
    @Binding var text: String
    @State private var dynamicHeight: CGFloat = 44
    
    var placeholder: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .onChange(of: text) {
                    calculateHeight()
                }
                .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
            
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            calculateHeight()
        }
    }
    
    private func calculateHeight() {
        let maxSize = CGSize(width: UIScreen.main.bounds.width - 32, height: .infinity)
        let size = CGSize(width: maxSize.width, height: CGFloat.greatestFiniteMagnitude)
        
        let text = self.text.isEmpty ? " " : self.text
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17)]
        let rect = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        DispatchQueue.main.async {
            self.dynamicHeight = rect.height + 24
        }
    }
}
