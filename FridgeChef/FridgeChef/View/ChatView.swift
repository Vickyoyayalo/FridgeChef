//
//  ChatView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/10.
//

import SwiftUI
import PhotosUI
import IQKeyboardManagerSwift
import FirebaseAuth
import SDWebImageSwiftUI

struct ChatView: View {
    @ObservedObject var foodItemStore: FoodItemStore
    @StateObject private var viewModel: ChatViewModel
    
    init(foodItemStore: FoodItemStore) {
        self.foodItemStore = foodItemStore
        _viewModel = StateObject(wrappedValue: ChatViewModel(foodItemStore: foodItemStore))
    }
    
    var body: some View {
        NavigationView {
            if Auth.auth().currentUser != nil {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    
                    GeometryReader { geometry in
                        VStack {
                            if viewModel.messages.isEmpty {
                                VStack {
                                    Image("Chatmonster")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 300)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.clear)
                            }
                        }
                        .onTapGesture {
                            IQKeyboardManager.shared.resignFirstResponder()
                        }
                        
                        VStack {
                            ZStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            viewModel.isSearchVisible.toggle()
                                        }
                                    }) {
                                        Image(systemName: viewModel.isSearchVisible ? "xmark.circle.fill" : "magnifyingglass")
                                            .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                            .imageScale(.medium)
                                            .padding()
                                    }
                                }
                                
                                Image("FridgeChefLogo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 38)
                                    .padding(.top)
                            }
                            
                            if viewModel.isSearchVisible {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.orange)
                                        .padding(.leading, 8)
                                    
                                    TextField("Search messages...", text: $viewModel.searchText)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(.vertical, 8)
                                        .padding(.trailing, 8)
                                    
                                    if !viewModel.searchText.isEmpty {
                                        Button(action: {
                                            self.viewModel.searchText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.orange)
                                                .padding(.trailing, 8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).opacity(0.3))
                                .padding(.horizontal)
                                .transition(.move(edge: .trailing))
                            }
                            
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(viewModel.filteredMessages) { message in
                                            messageView(for: message)
                                                .id(message.id)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .onChange(of: viewModel.messages.count) { newValue, _ in
                                        if let lastMessage = viewModel.messages.last, let id = lastMessage.id {
                                            DispatchQueue.main.async {
                                                withAnimation {
                                                    proxy.scrollTo(id, anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                }
                                .scrollIndicators(.hidden)
                            }
                            
                            if viewModel.isWaitingForResponse {
                                MonsterAnimationView()
                            }
                            
                            if let image = viewModel.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .cornerRadius(15)
                                    .shadow(radius: 3)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                    .onTapGesture {
                                        self.viewModel.showChangePhotoDialog = true
                                    }
                                    .confirmationDialog("Wanna Change?", isPresented: $viewModel.showChangePhotoDialog, titleVisibility: .visible) {
                                        Button("Change") {
                                            viewModel.showPhotoOptions = true
                                        }
                                        Button("Remove", role: .destructive) {
                                            self.viewModel.image = nil
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    }
                            }
                            
                            HStack {
                                Button(action: { viewModel.showPhotoOptions = true }, label: {
                                    Image(systemName: "camera.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                })
                                .padding(.leading, 15)
                                .fixedSize()
                                .confirmationDialog("Choose your photos from", isPresented: $viewModel.showPhotoOptions, titleVisibility: .visible) {
                                    Button("Camera") { viewModel.photoSource = .camera }
                                    Button("Photo Library") { viewModel.photoSource = .photoLibrary }
                                }
                                
                                Spacer(minLength: 20)
                                
                                PlaceholderTextEditor(text: $viewModel.inputText, placeholder: "Want ideas? 🥙 ...")
                                    .frame(minHeight: 40, maxHeight: 60)
                                
                                Spacer(minLength: 20)
                                
                                Button(action: viewModel.sendMessage) {
                                    Image(systemName: "paperplane.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                }
                                .padding(.trailing, 15)
                                .fixedSize()
                            }
                            .padding(.bottom, 8)
                        }
                        
                    }
                    .onAppear {
                        viewModel.onAppear()
                    }
                    .onDisappear {
                        viewModel.onDisappear()
                    }
                    if viewModel.isWaitingForResponse {
                        ProgressOverlay(showing: true, message: "Generating response...")
                            .zIndex(1)
                    }
                }
                .alert(item: $viewModel.activeAlert) { activeAlert in
                    switch activeAlert {
                    case .error(let errorMessage):
                        return Alert(
                            title: Text("Error"),
                            message: Text(errorMessage.message),
                            dismissButton: .default(Text("OK")) {
                                viewModel.activeAlert = nil
                            }
                        )

                    case .ingredient(let message):
                        return Alert(
                            title: Text("Ingredient Added"),
                            message: Text(message),
                            dismissButton: .default(Text("OK")) {
                                viewModel.activeAlert = nil
                            }
                        )

                    case .accumulation(let ingredient):
                        return Alert(
                            title: Text("Ingredient Already Exists"),
                            message: Text("Do you want to add \(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit) of \(ingredient.name) to the existing amount?"),
                            primaryButton: .default(Text("Accumulate"), action: {
                                viewModel.handleAccumulationChoice(for: ingredient, accumulate: true)
                            }),
                            secondaryButton: .cancel(Text("Keep Existing"), action: {
                                viewModel.handleAccumulationChoice(for: ingredient, accumulate: false)
                            })
                        )

                    case .regular(let title, let message):
                        return Alert(
                            title: Text(title),
                            message: Text(message),
                            dismissButton: .default(Text("OK")) {
                                viewModel.activeAlert = nil
                            }
                        )
                    }
                }
                .fullScreenCover(item: $viewModel.photoSource) { source in
                    ImagePicker(image: $viewModel.image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                        .ignoresSafeArea()
                }
            } else {
                VStack {
                    Text("Please login to continue chats!")
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Message View
    private func messageView(for message: Message) -> some View {
        return HStack {
            if let recipe = message.parsedRecipe {
                if message.role == .user {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let imageURL = message.imageURL, let url = URL(string: imageURL) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                        }
                        if let content = message.content {
                            Text(content)
                                .padding()
                                .background(Color.customColor(named: "NavigationBarTitle"))
                                .foregroundColor(.white)
                                .bold()
                                .cornerRadius(10)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        if let title = recipe.title {
                            Text("\(title) 🥙")
                                .font(.custom("ArialRoundedMTBold", size: 20))
                                .bold()
                                .padding(.bottom, 5)
                        }
                        
                        if !recipe.ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🥬【Ingredients】")
                                    .font(.custom("ArialRoundedMTBold", size: 18))
                                ForEach(recipe.ingredients) { ingredient in
                                    IngredientRow(
                                        viewModel: viewModel,
                                        ingredient: ingredient,
                                        addAction: viewModel.addIngredientToShoppingList,
                                        isInCart: foodItemStore.isIngredientInCart(ingredient.name)
                                    )
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                            
                            Button(action: {
                                if allIngredientsInCart(ingredients: recipe.ingredients) {
                                    addRemainingIngredientsToCart(ingredients: recipe.ingredients)
                                } else {
                                    addAllIngredientsToCart(ingredients: recipe.ingredients)
                                }
                            }) {
                                Text(allIngredientsInCart(ingredients: recipe.ingredients) ? "Add Remaining Ingredients to Cart" : "Add All Ingredients to Cart")
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(viewModel.isButtonDisabled ? 0.3 : 0.8)
                            .disabled(viewModel.isButtonDisabled)
                            .alert(isPresented: $viewModel.showAlert) {
                                Alert(
                                    title: Text(viewModel.alertTitle),
                                    message: Text(viewModel.alertMessage),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                        
                        if !recipe.steps.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🍳【Cooking Steps】")
                                    .font(.custom("ArialRoundedMTBold", size: 18))
                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .bold()
                                        Text(step)
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.3))
                            .cornerRadius(10)
                        }
                        
                        if let link = recipe.link, let url = URL(string: link) {
                            Link(destination: url) {
                                HStack {
                                    Text("🔗 View Full Recipe")
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        
                        if let tips = recipe.tips {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("👩🏻‍🍳【Friendly Reminder】")
                                    .font(.custom("ArialRoundedMTBold", size: 18))
                                Text(tips)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    Spacer()
                }
            } else {
                if message.role == .user {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let imageURL = message.imageURL, let url = URL(string: imageURL) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                        }
                        if let content = message.content {
                            Text(content)
                                .padding()
                                .background(Color.customColor(named: "NavigationBarTitle"))
                                .foregroundColor(.white)
                                .bold()
                                .cornerRadius(10)
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        if let content = message.content {
                            Text(content)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func allIngredientsInCart(ingredients: [ParsedIngredient]) -> Bool {
        return ingredients.allSatisfy { viewModel.isIngredientInCart($0) }
    }
    
    private func addRemainingIngredientsToCart(ingredients: [ParsedIngredient]) {
        var alreadyInCart = [String]()
        var addedToCart = [String]()
        
        for ingredient in ingredients {
               if viewModel.addIngredientToCart(ingredient) {
                let success = viewModel.addIngredientToShoppingList(ingredient)
                if success {
                    addedToCart.append(ingredient.name)
                }
            } else {
                alreadyInCart.append(ingredient.name)
            }
        }
        
        if addedToCart.isEmpty {
            viewModel.alertTitle = "No New Ingredients Added"
            viewModel.alertMessage = "All ingredients are already in your cart."
        } else {
            viewModel.alertTitle = "Ingredients Added"
            viewModel.alertMessage = "Added: \(addedToCart.joined(separator: ", "))"
            
            if !alreadyInCart.isEmpty {
                viewModel.alertMessage += "\nAlready in cart: \(alreadyInCart.joined(separator: ", "))"
            }
        }
        viewModel.showAlert = true
    }
    
    private func addAllIngredientsToCart(ingredients: [ParsedIngredient]) {
        var addedToCart = [String]()
        
        for ingredient in ingredients {
            if viewModel.addIngredientToShoppingList(ingredient) {
                addedToCart.append(ingredient.name)
            }
        }
        viewModel.alertTitle = "Ingredients Added"
        viewModel.alertMessage = "Added: \(addedToCart.joined(separator: ", "))"
        viewModel.showAlert = true
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(foodItemStore: FoodItemStore())
    }
}
