//
//  DefaultRecipeDetailView.swift
//  RecipeBookUI
//
//  Created by Eymen on 17.08.2023.
//

import SwiftUI

struct DefaultRecipeDetailView: View {
    var recipe: DefaultRecipe
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView{
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading) {
                        VStack {
                            Image(recipe.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .padding(10)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x:0, y: 4)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                        .padding()
                        
                        Text(recipe.headline)
                            .font(.title).bold()
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                Text("Instructions:")
                                    .font(.title3).bold()
                                    .padding(.vertical, 5)
                                Text(recipe.instructions)
                                    .font(.body)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding()
                            
                            VStack(alignment: .leading) {
                                Text("Ingredients:")
                                    .font(.title3).bold()
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: -20) {
                                        ForEach(Array(recipe.ingredients.enumerated()), id: \.element) { index, ingredinet in
                                            Text(ingredinet)
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.7))
                                            
                                                .cornerRadius(6)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
//                        .frame(width: .infinity, height: 500, alignment: .bottomLeading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                    }
                }
                .background(.ultraThinMaterial)
                .navigationTitle(recipe.title)
                .navigationBarItems(trailing:
                    Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                    .onTapGesture {
                        dismiss()
                    })
            }
        }
    }
}
