//
//  FlowLayout.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/6.
//
//
//import SwiftUI
//
//struct FlowLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
//    let mode: Mode
//    let items: Data
//    let content: (Data.Element) -> Content
//
//    enum Mode {
//        case scrollable, vstack
//    }
//
//    init(mode: Mode, items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
//        self.mode = mode
//        self.items = items
//        self.content = content
//    }
//
//    var body: some View {
//        switch mode {
//        case .scrollable:
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack {
//                    ForEach(Array(items), id: \.self) { item in
//                        content(item)
//                    }
//                }
//            }
//        case .vstack:
//            VStack {
//                ForEach(Array(items), id: \.self) { item in
//                    content(item)
//                }
//            }
//        }
//    }
//}
//
//struct FlowLayout_Previews: PreviewProvider {
//    static var previews: some View {
//        FlowLayout(mode: .scrollable, items: ["Breakfast", "Lunch", "Dinner", "Dessert", "Brunch"]) { keyword in
//            Text(keyword)
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//                .background(Color.white.opacity(0.7))
//                .foregroundColor(.orange)
//                .bold()
//                .cornerRadius(20)
//                .shadow(radius: 10)
//        }
//        .previewLayout(.sizeThatFits)
//    }
//}
//
