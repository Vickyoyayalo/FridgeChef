//
//  CustomNavigationBarView.swift
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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.4)
            .edgesIgnoringSafeArea(.all)

            VStack {
                content
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitle(Text(title), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "arrowshape.turn.up.backward.circle.fill")
                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                    .imageScale(.large)
            }))
        }
    }
}

struct ParentView: View {
    var body: some View {
        NavigationView {
            CustomNavigationBarView(title: "FridgeChef") {
                Text("Your content here")
            }
            .navigationBarHidden(true)
        }
    }
}
