//
//  RecommendRecipeDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct RecommendRecipeDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showReview = false
    
    var recommendRecipes: RecommendRecipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Image(recommendRecipes.image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 445)
                    .overlay {
                        VStack {
                            Image(systemName: recommendRecipes.isFavorite ? "heart.fill" : "heart")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topTrailing)
                                .padding()
                                .font(.system(size: 30))
                                .foregroundStyle(recommendRecipes.isFavorite ? .yellow : .white)
                                .padding(.top, 40)
                            HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(recommendRecipes.name)
                                    .font(.custom("Nunito-Regular", size: 35, relativeTo: .largeTitle))
                                    .bold()
                                Text(recommendRecipes.type)
                                    .font(.system(.headline, design: .rounded))
                                    .padding(.all, 5)
                                    .background(.black)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottomLeading)
                            .foregroundStyle(.white)
                            .padding()
                                
                                if let rating = recommendRecipes.rating, !showReview {
                                        Image(rating.image)
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .padding([.bottom, .trailing])
                                            .transition(.scale)
                                    }
                                }
                                .animation(.spring(response: 0.2, dampingFraction: 0.3, blendDuration: 0.3), value: recommendRecipes.rating)
                        }
                    }
                
                Text(recommendRecipes.description)
                    .padding()
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("ADDRESS")
                            .font(.system(.headline, design: .rounded))
                        
                        Text(recommendRecipes.location)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text("PHONE")
                            .font(.system(.headline, design: .rounded))
                        
                        Text(recommendRecipes.phone)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                NavigationLink(
                    destination:
                        MapView(location: recommendRecipes.location)
                            .toolbarBackground(.hidden, for: .navigationBar)
                            .edgesIgnoringSafeArea(.all)
                            
                ) {
                    MapView(location: recommendRecipes.location, interactionMode: [])
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding()
                }
                
                Button {
                    self.showReview.toggle()
                } label: {
                    Text("Rate it")
                        .font(.system(.headline, design: .rounded))
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .tint(Color("NavigationBarTitle"))
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 25))
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 20)
                 
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Text("\(Image(systemName: "chevron.left"))")
                }
            }
        }
        .ignoresSafeArea()
        .overlay(
            self.showReview ?
                ZStack {
                    ReviewView(isDisplayed: $showReview, recommendRecipes: recommendRecipes)
                }
            : nil
        )
        .toolbar(self.showReview ? .hidden : .visible)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        RecommendRecipeDetailView(recommendRecipes:RecommendRecipe(name: "CASK Pub and Kitchen", type: "Thai", location: "22 Charlwood Street London SW1V 2DY Pimlico", phone: "432-344050", description: "With kitchen serving gourmet burgers. We offer food every day of the week, Monday through to Sunday. Join us every Sunday from 4:30 – 7:30pm for live acoustic music!", image: "cask", isFavorite: false))
    }
    .tint(.white)
}

