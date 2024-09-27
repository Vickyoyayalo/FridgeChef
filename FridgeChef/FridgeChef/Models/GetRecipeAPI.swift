//
//  GetRecipeAPI.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/26.
//

import SwiftUI

struct TryRecipeView: View {
    @State private var recipes = [Recipe]()
    @State private var recipeInfo: RecipeInfo?
    @State private var instructionAnalysis: InstructionAnalysis?

    var body: some View {
        NavigationView {
            List(recipes, id: \.id) { recipe in
                VStack(alignment: .leading) {
                    Text(recipe.title)
                        .font(.headline)
                    if let info = recipeInfo, recipe.id == info.id {
                        Text("Calories: \(info.calories)")
                        Text("Fat: \(info.fat)g")
                    }
                }
                .onTapGesture {
                    fetchRecipeInfo(for: recipe.id)
                }
            }
            .navigationTitle("Recipes")
            .onAppear {
                searchRecipes(query: "pasta")
            }
        }
    }

    func searchRecipes(query: String) {
        let apiKey = "YOUR-API-KEY"
        let url = URL(string: "https://api.spoonacular.com/recipes/complexSearch?query=\(query)&apiKey=\(apiKey)")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(RecipeResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.recipes = decodedResponse.results
                    }
                }
            }
        }.resume()
    }

    func fetchRecipeInfo(for id: Int) {
        let apiKey = "YOUR-API-KEY"
        let url = URL(string: "https://api.spoonacular.com/recipes/\(id)/information?apiKey=\(apiKey)&includeNutrition=false")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedInfo = try? JSONDecoder().decode(RecipeInfo.self, from: data) {
                    DispatchQueue.main.async {
                        self.recipeInfo = decodedInfo
                    }
                }
            }
        }.resume()
    }

    func analyzeInstructions(instructions: String) {
        let apiKey = "YOUR-API-KEY"
        let url = URL(string: "https://api.spoonacular.com/recipes/analyzeInstructions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "instructions=\(instructions)&apiKey=\(apiKey)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let decodedAnalysis = try? JSONDecoder().decode(InstructionAnalysis.self, from: data) {
                    DispatchQueue.main.async {
                        self.instructionAnalysis = decodedAnalysis
                    }
                }
            }
        }.resume()
    }
}

struct RecipeResponse: Codable {
    var results: [Recipe]
}

struct Recipe: Codable {
    var id: Int
    var title: String
}

struct RecipeInfo: Codable {
    var id: Int
    var calories: Int
    var fat: String
}

struct InstructionAnalysis: Codable {
    // Add properties as per the API response
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            TryRecipeView()
        }
    }
}
