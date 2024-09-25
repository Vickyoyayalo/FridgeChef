//
//  RecommendedRecipeCardView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//

import SwiftUI

struct RecommendedRecipeCardView: View {
    let image: UIImage
    let title: String
    @State private var isLiked: Bool = false
    @State private var showReview = false
    
    var body: some View {
        HStack {
            Image(uiImage: image)
                .aspectRatio(1, contentMode: .fill)
                .padding(.trailing, 4)
            
            VStack (alignment: .leading, spacing: 4) {
                HStack {
                    Text("早餐")
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.6272217631, blue: 0.7377799153, alpha: 1)))
                    Spacer()
                    
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(isLiked ? Color("NavigationBarTitle") : .gray)  // 按下後變橘色
                        .onTapGesture {
                            isLiked.toggle()  // 切換狀態
                        }
                    
                }
                Text(title)
                    .fontWeight(.medium)
                
                HStack (spacing: 2) {
                    ForEach(0 ..< 5) { item in
                        Image(uiImage: #imageLiteral(resourceName: "star"))
                            .renderingMode(.template)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                    
                    Text("120 大卡")
                        .font(.caption)
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.leading)
                }
                
                HStack {
                    Image(uiImage: #imageLiteral(resourceName: "time"))
                    Text("10 分鐘")
                        .font(.caption2)
                        .foregroundColor(Color("GrayColor"))
                    
                    
                    Image(uiImage: #imageLiteral(resourceName: "serving"))
                        .padding(.leading)
                    Text("1 人份")
                        .font(.caption2)
                        .foregroundColor(Color("GrayColor"))
                    
                }
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color("LightGrayColor"))
        .cornerRadius(18.0)
    }
}
