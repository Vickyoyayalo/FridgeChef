//
//  CustomBackButtonModifier.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//
import SwiftUI

struct CustomNavigationBarView<Content: View>: View {
    @Environment(\.presentationMode) var presentationMode
    let content: Content
    let title: String
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(
            action: {
        self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrowshape.turn.up.backward.circle.fill")
                .foregroundColor(.gray)
                .imageScale(.large)
        })
        .navigationBarTitle(Text(title), displayMode: .inline)
    }
}

