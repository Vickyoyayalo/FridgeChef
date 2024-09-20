//
//  HomeView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//

import SwiftUI

struct HomeView: View {
    @State private var search: String = ""

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

                    SectionTitleView(title: "Recommended")

                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_1"), title: "Blueberry Muffins")
                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_2"), title: "Glazed Salmon")
                    RecommendedRecipeCardView(image: #imageLiteral(resourceName: "reco_3"), title: "Asian Glazed Chicken Thighs")
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("FridgeChef")
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

