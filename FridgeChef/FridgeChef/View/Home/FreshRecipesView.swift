//
//  FreshRecipesView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//


import SwiftUI

struct FreshRecipesView: View {
    var body: some View {
        VStack (alignment: .leading, spacing: 16) {
            SectionTitleView(title: "👩🏻‍🍳熱騰騰新鮮食譜唷～")
            
            ScrollView (.horizontal, showsIndicators: false) {
                HStack (spacing: 16) {
                    RecipeCard(image: #imageLiteral(resourceName: "fresh_recipe_1"))
                    RecipeCard(image: #imageLiteral(resourceName: "fresh_recipe_2"))
                }
            }
        }
    }
}

struct RecipeCard: View {
    let image: UIImage
    @State private var isLiked: Bool = false  // 用來追蹤是否被按下愛心
    @State private var showReview = false  // 用來顯示ReviewView
   
    
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 8) {
                // 愛心圖示，根據 isLiked 狀態改變圖示
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isLiked ? Color("NavigationBarTitle") : .gray)  // 按下後變橘色
                    .onTapGesture {
                        isLiked.toggle()  // 切換愛心狀態
                    }
                    .padding(.bottom, 60)
                
                Text("早餐")
                    .font(.caption)
                    .foregroundColor(Color(#colorLiteral(red: 0.07058823529, green: 0.5607843137, blue: 0.6823529412, alpha: 1)))
                Text("法式藍莓吐司")
                    .fontWeight(.medium)
                    .lineLimit(nil)
                
                HStack (spacing: 2) {
                    ForEach(0 ..< 5) { item in
                        Image(uiImage: #imageLiteral(resourceName: "star"))
                            .renderingMode(.template)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                
                Text("120 大卡")
                    .font(.caption)
                    .foregroundColor(Color("PrimaryColor"))
                
                HStack {
                    Image(uiImage: #imageLiteral(resourceName: "time"))
                    Text("10 分鐘")
                        .font(.caption2)
                        .foregroundColor(Color("GrayColor"))
                    Spacer()
                    
                    Image(uiImage: #imageLiteral(resourceName: "serving"))
                    Text("1 人份")
                        .font(.caption2)
                        .foregroundColor(Color("GrayColor"))
                }
                
                // 新增一個 "Rate Me" 按鈕，單獨觸發 ReviewView
//                Button(action: {
//                    showReview.toggle()  // 顯示 ReviewView
//                }) {
//                    Text("Rate Me")
//                        .font(.system(size: 16, weight: .bold))
//                        .padding()
//                        .background(Color("NavigationBarTitle"))
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//                .padding(.top, 10)
                
            }
            .frame(width: 147)
            .padding()
            .background(Color("LightGrayColor"))
            .cornerRadius(20.0)
            
            // 食譜圖片
            Image(uiImage: image)
                .offset(x: 45, y: -60)
        }
        .padding(.trailing, 25)
    }
}
