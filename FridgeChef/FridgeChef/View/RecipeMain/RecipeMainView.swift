//
//  RecipeMainView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/5.
//

import SwiftUI

struct RecipeMainView: View {
    @ObservedObject var viewModel: RecipeSearchViewModel
    @ObservedObject var foodItemStore: FoodItemStore
    @State private var showingAddGroceryForm = false
    @State private var searchQuery: String = ""
    @State private var isShowingDefaultPage = true
    @State private var selectedRecipe: Recipe? = nil
    var showEditAndAddButtons: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                content
            }
            .navigationBarItems(
                leading: showEditAndAddButtons ? EditButton().bold() : nil,
                trailing: showEditAndAddButtons ? addButton : nil
            )
            .navigationDestination(for: Recipe.self) { recipe in
                self.recipeDetailDestination(for: recipe)
            }
        }
        .onChange(of: selectedRecipe) { newRecipe in
            if newRecipe != nil {
                navigateToRecipeDetail()
            }
        }
    }
    
    private func recipeDetailDestination(for recipe: Recipe) -> some View {
        RecipeDetailView(recipeId: recipe.id, viewModel: viewModel, foodItemStore: foodItemStore)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow, Color.orange]),
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(0.4)
        .edgesIgnoringSafeArea(.all)
    }

    private var content: some View {
        VStack {
            if isShowingDefaultPage {
                DefaultRecipeView(recipeManager: RecipeManager())
            } else {
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.recipes.isEmpty {
                    recipeListView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else {
                    emptyStateView
                }
            }
        }
        .navigationTitle("Recipe 👩🏻‍🍳")
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
        .onSubmit(of: .search) {
            handleSearch()
        }
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(
                title: Text("Error"),
                message: Text(errorMessage.message),
                dismissButton: .default(Text("Sure")) {
                    viewModel.errorMessage = nil
                }
            )
        }
        .sheet(isPresented: $showingAddGroceryForm) {
            AddGroceryForm(viewModel: AddGroceryFormViewModel())
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Spacer()
        }
    }

    private var recipeListView: some View {
        List(viewModel.recipes, id: \.id) { recipe in
            self.recipeRow(for: recipe)
        }
        .listStyle(PlainListStyle())
    }

    private func errorView(_ errorMessage: ErrorMessage) -> some View {
        VStack {
            Spacer()
            Text("wrong：\(errorMessage.message)")
                .foregroundColor(.red)
                .padding()
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("Opps...Let's try again.. \nSearch by keywords🕵🏻‍♂️")
                .foregroundColor(.gray)
            Spacer()
        }
    }

    private func handleSearch() {
        if !searchQuery.isEmpty {
            isShowingDefaultPage = false
            viewModel.searchRecipes(query: searchQuery)
        } else {
            isShowingDefaultPage = true
        }
    }

    private func navigateToRecipeDetail() {
        guard let recipe = selectedRecipe else { return }
        selectedRecipe = nil  // Clear selection to allow repeated navigation
        DispatchQueue.main.async {
            selectedRecipe = recipe
        }
    }

    var addButton: some View {
        Button(action: {
            showingAddGroceryForm = true
        }, label: {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        })
    }

    private func recipeRow(for recipe: Recipe) -> some View {
        RecipeRowView(
            recipe: recipe,
            toggleFavorite: {
                self.viewModel.toggleFavorite(for: recipe.id)
            }
        )
        .onTapGesture {
            self.selectedRecipe = recipe
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct RecipeMainView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeMainView(viewModel: RecipeSearchViewModel(), foodItemStore: FoodItemStore())
    }
}
