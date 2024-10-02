//
//  RecipeRowView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//
//import SwiftUI
//
//struct RecipeRowView: View {
//    let recipe: Recipe
//    let toggleFavorite: () -> Void
//    @State private var animate = false
//    @ObservedObject var viewModel: RecipeSearchViewModel
//    
//    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Image Handling
//            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
//                AsyncImage(url: url) { phase in
//                    switch phase {
//                    case .empty:
//                        ProgressView()
//                            .frame(maxWidth: .infinity, maxHeight: 200)
//                            .background(Color(.systemGray5))
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(maxWidth: .infinity, maxHeight: 200)
//                            .clipped()
//                    case .failure:
//                        Image("newphoto") // Ensure you have a placeholder image in your assets
//                            .resizable()
//                            .scaledToFit()
//                            .frame(maxWidth: .infinity, maxHeight: 200)
//                            .foregroundColor(.gray)
//                            .background(Color(.systemGray5))
//                    @unknown default:
//                        EmptyView()
//                    }
//                }
//                .cornerRadius(10)
//                .shadow(radius: 5)
//            } else {
//                Image(systemName: "newphoto")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxWidth: .infinity, maxHeight: 200)
//                    .foregroundColor(.gray)
//                    .background(Color(.clear))
//                    .cornerRadius(10)
//                    .shadow(radius: 5)
//            }
//
//            // Recipe Title and Favorite Button
//            HStack {
//                Text(recipe.title)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .lineLimit(2)
//                    .fixedSize(horizontal: false, vertical: true)
//
//                Spacer()
//
//                Button(action: {
//                    withAnimation(.easeInOut(duration: 0.3)) {
//                        toggleFavorite()
//                        animate = true
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        animate = false
//                    }
//                }) {
//                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
//                        .foregroundColor(Color(UIColor(named: recipe.isFavorite ? "NavigationBarTitle" : "GrayColor") ?? UIColor.gray))
//                        .scaleEffect(animate ? 1.5 : 1.0)
//                        .opacity(animate ? 0.5 : 1.0)
//                        .animation(.easeInOut(duration: 0.3), value: animate)
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
//            
//        }
//        .padding()
//        .background(Color(.white).opacity(0.3))
//        .cornerRadius(15)
//        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
//    }
//}

import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    let toggleFavorite: () -> Void
    @State private var animate = false
    @ObservedObject var viewModel: RecipeSearchViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // 图片处理
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .background(Color(.systemGray5))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipped()
                    case .failure:
                        Image("newphoto")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .foregroundColor(.gray)
                            .background(Color(.systemGray5))
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(10)
                .shadow(radius: 5)
            } else {
                Image(systemName: "RecipeFood")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .foregroundColor(.gray)
                    .background(Color(.clear))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            // 食谱标题和收藏按钮
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .fontWeight(.bold) // 加粗，与 listResults 一致
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 20) // 添加左侧内边距

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        toggleFavorite()
                        animate = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        animate = false
                    }
                }) {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(Color(UIColor(named: recipe.isFavorite ? "NavigationBarTitle" : "GrayColor") ?? UIColor.gray))
                        .scaleEffect(animate ? 1.5 : 1.0)
                        .opacity(animate ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: animate)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20) // 添加右侧内边距
            }
            .padding(.vertical) // 添加上下内边距
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.7))
        )
        .padding(.horizontal) // 添加左右内边距
        .padding(.vertical, 5) // 添加上下内边距，使每个 cell 有间距
        .shadow(radius: 10)
    }
}
struct RecipeRowView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeRowView(
            recipe: Recipe(
                id: 1,
                title: "示例食谱",
                image: nil,
                servings: 1,
                readyInMinutes: 0,
                summary: "Sample",
                isFavorite: false
            ),
            toggleFavorite: {},
            viewModel: RecipeSearchViewModel()
        )
    }
}

