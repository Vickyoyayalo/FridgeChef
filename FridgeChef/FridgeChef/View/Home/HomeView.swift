//
//  HomeView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//

import SwiftUI

struct HomeView: View {
    @State private var search: String = ""
    @State private var showReview = false
    @State private var recommendRecipe = RecommendRecipe(name: "法式藍莓吐司", type: "早餐", location: "廚房", phone: "000-000000", description: "美味的早餐選擇", image: "blueberry_toast", isFavorite: false)
        
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bonjour, Vicky 🍻")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("SecondaryColor"))
                    
                    Text("今天想煮點...")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("NavigationBarTitle"))
                    
                    FreshRecipesView()
                    
                    SectionTitleView(title: "推薦料理 🤤 ")
                    
                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_1"), title: "藍莓馬芬")
                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_2"), title: "北歐鮭魚")
                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_3"), title: "義式香料雞腿")
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("FridgeChef")
            //            .navigationBarItems(leading: menu(), trailing: Notification)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Recipes")
            
            .overlay(
                self.showReview ?
                ZStack {
                    ReviewView(isDisplayed: $showReview, recommendRecipes: recommendRecipe)
                }
                : nil
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

