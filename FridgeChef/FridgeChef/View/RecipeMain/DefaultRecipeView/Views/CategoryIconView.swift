//
//  CategoryIconView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/6.
//
//
//import SwiftUI
//
//struct CategoryIconView: View {
//    let category: String
//    
//    var body: some View {
//        VStack {
//            Image(systemName: categoryIconName(for: category))
//                .resizable()
//                .scaledToFit()
//                .frame(width: 30, height: 30)
//                .foregroundColor(.orange)
//                .padding()
//                .background(Color.white)
//                .opacity(0.7)
//                .cornerRadius(10)
//                .shadow(radius: 5)
//            
//            Text(category)
//                .foregroundColor(.primary)
//                .font(.custom("ArialRoundedMTBold", size: 15))
//                .fontWeight(.semibold)
//                
//        }
//    }
//    
//    func categoryIconName(for category: String) -> String {
//        switch category.lowercased() {
//        case "breakfast":
//            return "sunrise.fill"
//        case "lunch":
//            return "leaf.fill"
//        case "dinner":
//            return "moon.fill"
//        default:
//            return "questionmark.circle.fill"
//        }
//    }
//}
//
//struct CategoryIconView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryIconView(category: "Breakfast")
//            .previewLayout(.sizeThatFits)
//    }
//}
//
