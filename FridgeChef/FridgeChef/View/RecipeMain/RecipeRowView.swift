//
//  RecipeRowView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//
import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    let toggleFavorite: () -> Void
    @State private var animate = false
    
    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image Handling
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
                        Image("newphoto") // Ensure you have a placeholder image in your assets
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
                Image(systemName: "newphoto")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .foregroundColor(.gray)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            // Recipe Title and Favorite Button
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

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
                        .foregroundColor(recipe.isFavorite ? .orange : .gray)
                        .scaleEffect(animate ? 1.5 : 1.0)
                        .opacity(animate ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: animate)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}
