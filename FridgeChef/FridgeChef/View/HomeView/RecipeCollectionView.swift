//
//  RecipeCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.
//

import SwiftUI

struct RecipeCollectionView: View {
    let recipe: Recipe
    let toggleFavorite: () -> Void
    
    @State private var animate = false

    var body: some View {
        HStack {
            
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(18.0)
                        .shadow(radius: 5)
                        .padding(.trailing, 4)
                } placeholder: {
                    ProgressView()
                        .frame(width: 80, height: 80)
                }
            } else {
                
                Image("RecipeFood")
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(18.0)
                    .shadow(radius: 5)
                    .padding(.trailing, 4)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
           
                if let dishType = recipe.dishTypes.first {
                    Text(dishType.capitalized)
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.6272217631, blue: 0.7377799153, alpha: 1)))
                } else {
                    Text("Unknown Type")
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .foregroundColor(Color.gray)
                }
                
                Text(recipe.title)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "person.2")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(Color("GrayColor"))
                    
                    Text("\(recipe.servings) Serving")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(Color("GrayColor"))
                    
                    Image(systemName: "clock")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(Color("GrayColor"))
                        .padding(.leading, 8)
                    
                    Text("\(recipe.readyInMinutes) mins")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(Color("GrayColor"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    toggleFavorite()
                    animate = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animate = false
                }
            }, label: {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor((recipe.isFavorite) ? (Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)) : Color.gray)
                    .scaleEffect(animate ? 1.5 : 1.0)
                    .opacity(animate ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animate)
            })
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(18.0)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecipeCollectionView_Previews: PreviewProvider {
    static let sampleRecipe = Recipe(
        id: 999,
        title: "Find more Favorite Recipe!",
        image: nil,
        servings: 2,
        readyInMinutes: 15,
        summary: "Get more Favorites.",
        isFavorite: false,
        dishTypes: ["Breakfast"]
    )
    
    static var previews: some View {
        
        let sampleViewModel = RecipeSearchViewModel()
        let sampleFoodItemStore = FoodItemStore()
        
        return NavigationView {
            NavigationLink(
                destination: RecipeMainView(
                    viewModel: sampleViewModel,
                    foodItemStore: sampleFoodItemStore,
                    showEditAndAddButtons: false
                )
            ) {
                RecipeCollectionView(
                    recipe: sampleRecipe,
                    toggleFavorite: {}
                )
            }
        }
    }
}
