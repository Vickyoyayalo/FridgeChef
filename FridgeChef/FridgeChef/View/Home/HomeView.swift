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
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今天想煮點 🥙 ...")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("SecondaryColor"))

//                    FreshRecipesView()
//
//                    SectionTitleView(title: "推薦料理 🤤 ")
//
//                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_1"), title: "藍莓馬芬")
//                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_2"), title: "北歐鮭魚")
//                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_3"), title: "義式香料雞腿")
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Bonjour, Vicky 🍻")
//            .navigationBarItems(leading: menu(), trailing: Notification)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Recipes")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

