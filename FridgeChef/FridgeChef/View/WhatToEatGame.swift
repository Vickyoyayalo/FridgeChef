//
//  WhatToEatGame.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/25.
//
import SwiftUI

struct FoodCategory: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let foods: [String]
    
    static func == (lhs: FoodCategory, rhs: FoodCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WhatToEatGameView: View {
    @State var degree = 90.0
    @State private var selectedFood: (category: String, food: String)?
    @State private var selectedMonsterImage: String?
    @State private var showCategoryInitial = true
    @State private var showingRecipeSheet = false

    let foodCategories: [FoodCategory] = [
        FoodCategory(category: "Japanese", foods: ["Sushi", "Ramen", "Sashimi"]),
        FoodCategory(category: "Western", foods: ["Pizza", "Burger", "Steak"]),
        FoodCategory(category: "Chinese", foods: ["Dumplings", "Sweet and Sour Pork", "Peking Duck"]),
        FoodCategory(category: "Korean", foods: ["Kimchi", "Bulgogi", "Bibimbap"]),
        FoodCategory(category: "Italian", foods: ["Pasta", "Lasagna", "Risotto"]),
        FoodCategory(category: "Thai", foods: ["Pad Thai", "Tom Yum Soup", "Green Curry"]),
        FoodCategory(category: "Mexican", foods: ["Tacos", "Burritos", "Quesadilla"]),
        FoodCategory(category: "Indian", foods: ["Curry", "Biryani", "Samosa"]),
        FoodCategory(category: "French", foods: ["Croissant", "Quiche", "Baguette"]),
        FoodCategory(category: "Greek", foods: ["Gyro", "Moussaka", "Souvlaki"]),
        FoodCategory(category: "Spanish", foods: ["Paella", "Tapas", "Churros"]),
        FoodCategory(category: "Turkish", foods: ["Kebab", "Baklava", "Pide"]),
        FoodCategory(category: "Lebanese", foods: ["Falafel", "Hummus", "Tabbouleh"]),
        FoodCategory(category: "Moroccan", foods: ["Tagine", "Couscous", "Harira"]),
        FoodCategory(category: "Vietnamese", foods: ["Pho", "Banh Mi", "Spring Rolls"]),
        FoodCategory(category: "Brazilian", foods: ["Churrasco", "Feijoada", "Pão de Queijo"]),
        FoodCategory(category: "Malaysian", foods: ["Nasi Lemak", "Laksa", "Satay"]),
        FoodCategory(category: "Peruvian", foods: ["Ceviche", "Lomo Saltado", "Aji de Gallina"]),
        FoodCategory(category: "Japanese", foods: ["Sushi", "Ramen", "Tempura", "Udon", "Katsudon", "Takoyaki", "Miso Soup", "Sashimi", "Onigiri", "Yakitori"]),
        FoodCategory(category: "Chinese", foods: ["Dumplings", "Sweet and Sour Pork", "Peking Duck", "Kung Pao Chicken", "Mapo Tofu", "Fried Rice", "Spring Rolls", "Hot Pot", "Xiao Long Bao", "Char Siu"]),
        FoodCategory(category: "Korean", foods: ["Kimchi", "Bulgogi", "Bibimbap", "Japchae", "Samgyeopsal", "Tteokbokki", "Sundubu-jjigae", "Gimbap", "Galbi", "Naengmyeon"]),
        FoodCategory(category: "Thai", foods: ["Pad Thai", "Tom Yum Soup", "Green Curry", "Som Tum", "Massaman Curry", "Pad See Ew", "Mango Sticky Rice", "Panang Curry", "Kai Yang", "Tom Kha Gai"])
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
           
            LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .hueRotation(Angle(degrees: degree))
                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: degree)
                .onAppear {
                    degree += 360
                }
            
            WheelView(degree: $degree, array: foodCategories.map { $0.category }, circleSize: 500)
                .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 20)
                .scaleEffect(0.9)
            
            Image("WhatToEatLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 350, height: 250)
                .padding(.top, -5)
            
            VStack {
                Spacer()
                
                if let selectedFood = selectedFood {
                    VStack(spacing: 10) {
                        if showCategoryInitial {
                            Text(String(selectedFood.category.prefix(1)).uppercased())
                                .font(.custom("ArialRoundedMTBold", size: 150))
                                .bold()
                                .foregroundColor(.orange)
                                .transition(.opacity)
                                .offset(y: 100)
                        } else {
                            VStack {
                                
                                Text(selectedFood.category)
                                    .bold()
                                    .font(.custom("ArialRoundedMTBold", size: 30))
                                    .foregroundColor(.white)
                                    .padding(.bottom, -5)
                                    .offset(y: 130)
                                    .shadow(radius: 8)
                                
                                Text(selectedFood.food)
                                    .font(.custom("ArialRoundedMTBold", size:40))
                                    .foregroundColor(.yellow)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 350)
                                    .offset(y: 130)
                                    .shadow(radius: 8)
                            }
                            .transition(.scale)
                        }
                        
                        if let monsterImage = selectedMonsterImage {
                            Image(monsterImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 350, height: 350)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                                .transition(.scale)
                                .offset(y: 100)
                        }
                    }
                    .animation(.easeInOut(duration: 0.6), value: showCategoryInitial)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                showCategoryInitial = false
                            }
                        }
                    }
                    .onDisappear {
                        showCategoryInitial = true
                    }
                }
                
                Spacer()
                
                Spacer().frame(height: 30)
                
                VStack(spacing: 20) {
                    SpinButton(action: {
                        spinWheelAndPickFood()
                    })
                    
                    HStack(spacing: 18) {
                        ResetButton(action: {
                            withAnimation {
                                selectedFood = nil
                                selectedMonsterImage = nil
                            }
                        })
                        
                        RecipeButton(action: {
                            showingRecipeSheet = true
                        })
                        .sheet(isPresented: $showingRecipeSheet) {
                            RecipeMainView(
                                viewModel: RecipeSearchViewModel(),
                                foodItemStore: FoodItemStore())
                        }
                    }
                   
                }
            }
            .padding(.bottom, 30)
            .frame(maxHeight: .infinity)
        }
    }

    func spinWheelAndPickFood() {
        let rotationIncrement = Double(360 / foodCategories.count)
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6, blendDuration: 1.0)) {
            degree += rotationIncrement * Double(foodCategories.count * 5)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let selectedCategory = foodCategories.randomElement()
            if let selectedCategory = selectedCategory {
                let randomFood = selectedCategory.foods.randomElement() ?? "Unknown"
                selectedFood = (category: selectedCategory.category, food: randomFood)
                
                let monsterImages = ["discomonster", "discomonster1", "discomonster2", "discomonster3", "discomonster4", "discomonster5"]
                selectedMonsterImage = monsterImages.randomElement()
            }
        }
    }
}

struct RecipeButton: View {
        var action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.title2)
                    Text("Recipes")
                        .fontWeight(.semibold)
                        .font(.custom("ArialRoundedMTBold", size:20))
                }
                .padding()
                .foregroundColor(.white)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
            }
        }
    }


struct WheelView: View {
    @Binding var degree: Double
    let array: [String]
    let circleSize: Double
    
    var body: some View {
        ZStack {
            let anglePerCount = Double.pi * 2.0 / Double(array.count)
            Circle().fill(
                AngularGradient(gradient: Gradient(colors: [.orange, .yellow, .green, .blue, .purple, .pink]), center: .center)
            )
            .hueRotation(Angle(degrees: degree))
            .frame(width: circleSize, height: circleSize)
            .shadow(radius: 10)
            .opacity(0.8)
            
            ForEach(0..<array.count, id: \.self) { index in
                let angle = Double(index) * anglePerCount + degree * Double.pi / 180
                let xOffset = CGFloat(circleSize / 2 - 50) * cos(angle)
                let yOffset = CGFloat(circleSize / 2 - 50) * sin(angle)
                Text("\(array[index].prefix(1).uppercased())")
                    .rotationEffect(Angle(degrees: -degree))
                    .offset(x: xOffset, y: yOffset)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .frame(width: circleSize, height: circleSize)
        .opacity(0.9)
    }
}

struct SpinButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.2.circlepath.circle.fill")
                    .font(.title2)
                Text("Spin and Pick Food")
                    .fontWeight(.semibold)
                    .font(.custom("ArialRoundedMTBold", size:20))
            }
            .padding()
            .foregroundColor(.white)
            .frame(width: 300)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: 1.0)
    }
}

struct ResetButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                Text("Reset")
                    .fontWeight(.semibold)
                    .font(.custom("ArialRoundedMTBold", size:20))
            }
            .padding()
            .foregroundColor(.white)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(30)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: 1.0)
    }
}

struct WhatToEatGameView_Previews: PreviewProvider {
    static var previews: some View {
        WhatToEatGameView()
    }
}
