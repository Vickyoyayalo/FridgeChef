//
//  WhatToEatGame.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/25.
//
import SwiftUI

// 結構體 FoodCategory，擁有多種食物
struct FoodCategory: Identifiable, Equatable {
    let id = UUID()
    let category: String  // 類別名稱
    let foods: [String]   // 該類別下的多種食物名稱
    
    static func == (lhs: FoodCategory, rhs: FoodCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WhatToEatGameView: View {
    @State var degree = 90.0
    @State private var selectedFood: (category: String, food: String)?
    @State private var selectedMonsterImage: String?
    @State private var showCategoryInitial = true

    let foodCategories: [FoodCategory] = [
        FoodCategory(category: "Japanese", foods: ["Sushi", "Ramen", "Tempura"]),
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
        // 更多亞洲類別的食物
        FoodCategory(category: "Japanese", foods: ["Sushi", "Ramen", "Tempura", "Udon", "Katsudon", "Takoyaki", "Miso Soup", "Sashimi", "Onigiri", "Yakitori"]),
        FoodCategory(category: "Chinese", foods: ["Dumplings", "Sweet and Sour Pork", "Peking Duck", "Kung Pao Chicken", "Mapo Tofu", "Fried Rice", "Spring Rolls", "Hot Pot", "Xiao Long Bao", "Char Siu"]),
        FoodCategory(category: "Korean", foods: ["Kimchi", "Bulgogi", "Bibimbap", "Japchae", "Samgyeopsal", "Tteokbokki", "Sundubu-jjigae", "Gimbap", "Galbi", "Naengmyeon"]),
        FoodCategory(category: "Thai", foods: ["Pad Thai", "Tom Yum Soup", "Green Curry", "Som Tum", "Massaman Curry", "Pad See Ew", "Mango Sticky Rice", "Panang Curry", "Kai Yang", "Tom Kha Gai"])
    ]

    var body: some View {
        ZStack(alignment: .top) {
            // 背景漸變色
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
                                // 移動食物類別和名稱的位置
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
                                    .lineLimit(nil) // 允許無限行
                                    .multilineTextAlignment(.center) // 多行居中對齊
                                    .frame(width: 350) // 限制寬度，強制換行
                                    .offset(y: 130)
                                    .shadow(radius: 8)
                            }
                            .transition(.scale)
                        }

                        // 顯示隨機選擇的可愛 monster 圖片
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

                    ResetButton(action: {
                        withAnimation {
                            selectedFood = nil
                            selectedMonsterImage = nil
                        }
                    })
                }
                .padding(.bottom) // 增加底部間距
            }
            .padding()
            .frame(maxHeight: .infinity)
        }
    }

    func spinWheelAndPickFood() {
        let rotationIncrement = Double(360 / foodCategories.count)
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6, blendDuration: 1.0)) {
            degree += rotationIncrement * Double(foodCategories.count * 5)
        }

        // 隨機選擇一個 FoodCategory
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let selectedCategory = foodCategories.randomElement()
            if let selectedCategory = selectedCategory {
                // 從該類別隨機選擇一個食物
                let randomFood = selectedCategory.foods.randomElement() ?? "Unknown"
                selectedFood = (category: selectedCategory.category, food: randomFood)
                
                let monsterImages = ["discomonster", "discomonster1", "discomonster2", "discomonster3", "discomonster4", "discomonster5"]
                selectedMonsterImage = monsterImages.randomElement()
            }
        }
    }
}

// 輪盤視圖
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

// 自訂 Spin 按鈕
struct SpinButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.2.circlepath.circle.fill")
                    .font(.title2)
                Text("Spin and Pick Food")
                    .fontWeight(.semibold)
                    .font(.title3)
            }
            .padding()
            .foregroundColor(.white)
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

// 自訂 Reset 按鈕
struct ResetButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                Text("Reset")
                    .fontWeight(.semibold)
                    .font(.title3)
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


//MARK: -功能完整ＧＯＯＤ
//import SwiftUI
//
//// 結構體 FoodGameItem，讓它遵守 Equatable 協議
//struct FoodGameItem: Identifiable, Equatable {
//    let id = UUID()
//    let category: String  // 食物類型
//    let name: String      // 食物名稱
//    let imageName: String // 對應的圖片名稱
//    
//    // 自動生成 Equatable 方法，這裡由 Swift 自動處理
//    static func == (lhs: FoodGameItem, rhs: FoodGameItem) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//import SwiftUI
//
//struct WhatToEatGameView: View {
//    @State var degree = 90.0
//    @State private var selectedFood: FoodGameItem?
//    @State private var selectedMonsterImage: String?
//    @State private var showCategoryInitial = true
//
//    let foodItems: [FoodGameItem] = [
//        FoodGameItem(category: "Japanese", name: "Sushi", imageName: "sushi"),
//        FoodGameItem(category: "Western", name: "Pizza", imageName: "pizza"),
//        FoodGameItem(category: "Chinese", name: "Dumplings", imageName: "dumplings"),
//        FoodGameItem(category: "Korean", name: "Kimchi", imageName: "kimchi"),
//        FoodGameItem(category: "Italian", name: "Pasta", imageName: "pasta"),
//        FoodGameItem(category: "Thai", name: "Pad Thai", imageName: "padthai"),
//        FoodGameItem(category: "Mexican", name: "Tacos", imageName: "tacos"),
//        // 新增的類別和食物
//        FoodGameItem(category: "Indian", name: "Curry", imageName: "curry"),
//        FoodGameItem(category: "French", name: "Croissant", imageName: "croissant"),
//        FoodGameItem(category: "Greek", name: "Gyro", imageName: "gyro"),
//        FoodGameItem(category: "Spanish", name: "Paella", imageName: "paella"),
//        FoodGameItem(category: "Turkish", name: "Kebab", imageName: "kebab"),
//        FoodGameItem(category: "Lebanese", name: "Falafel", imageName: "falafel"),
//        FoodGameItem(category: "Moroccan", name: "Tagine", imageName: "tagine"),
//        FoodGameItem(category: "Vietnamese", name: "Pho", imageName: "pho"),
//        FoodGameItem(category: "Brazilian", name: "Churrasco", imageName: "churrasco"),
//        FoodGameItem(category: "American", name: "Burger", imageName: "burger"),
//        FoodGameItem(category: "Malaysian", name: "Nasi Lemak", imageName: "nasilemak"),
//        FoodGameItem(category: "Peruvian", name: "Ceviche", imageName: "ceviche")
//    ]
//
//
//    var body: some View {
//        ZStack(alignment: .top) {
//            // 背景漸變色，調整動畫速度
//            LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
//                .ignoresSafeArea()
//                .hueRotation(Angle(degrees: degree))
//                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: degree)
//                .onAppear {
//                    degree += 360
//                }
//
//            WheelView(degree: $degree, array: foodItems.map { $0.category }, circleSize: 500)
//                .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 20)
//                .scaleEffect(0.9)
//
//            Image("WhatToEatLogo")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 350, height: 250)
//                .padding(.top, -5)
//
//            VStack {
//                Spacer()
//
//                if let selectedFood = selectedFood {
//                    VStack(spacing: 10) {
//                        if showCategoryInitial {
//                            Text(String(selectedFood.category.prefix(1)).uppercased())
//                                .font(.custom("ArialRoundedMTBold", size: 150))
//                                .bold()
//                                .foregroundColor(.orange)
//                                .transition(.opacity)
//                                .offset(y: 150)
//                        } else {
//                            VStack {
//                                // 移動食物類別和名稱的位置
//                                Text(selectedFood.category)
//                                    .bold()
//                                    .font(.custom("ArialRoundedMTBold", size: 30))
//                                    .foregroundColor(.white)
//                                    .padding(.bottom, -5) // 調整文字間距
//                                    .offset(y: 150)
//                                    .shadow(radius: 8)
//
//                                Text(selectedFood.name)
//                                    .font(.custom("ArialRoundedMTBold", size: 60))
//                                    .foregroundColor(.yellow)
//                                    .offset(y: 150)
//                                    .shadow(radius: 8)
//                            }
//                            .transition(.scale)
//                        }
//
//                        // 顯示隨機選擇的可愛照片
//                        if let monsterImage = selectedMonsterImage {
//                            Image(monsterImage)
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .frame(width: 350, height: 350)
//                                .clipShape(Circle())
//                                .shadow(radius: 10)
//                                .transition(.scale)
//                                .offset(y: 100)
//                        }
//                    }
//                    .animation(.easeInOut(duration: 0.6), value: showCategoryInitial)
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            withAnimation {
//                                showCategoryInitial = false
//                            }
//                        }
//                    }
//                    .onDisappear {
//                        showCategoryInitial = true
//                    }
//                }
//
//                Spacer()
//
//                Spacer().frame(height: 30)
//
//                VStack(spacing: 20) {
//                    SpinButton(action: {
//                        spinWheelAndPickFood()
//                    })
//
//                    ResetButton(action: {
//                        withAnimation {
//                            selectedFood = nil
//                            selectedMonsterImage = nil
//                        }
//                    })
//                }
//                .padding(.bottom) // 增加底部間距
//            }
//            .padding()
//            .frame(maxHeight: .infinity)
//        }
//    }
//
//    func spinWheelAndPickFood() {
//        let rotationIncrement = Double(360 / foodItems.count)
//        withAnimation(.spring(response: 1.5, dampingFraction: 0.6, blendDuration: 1.0)) {
//            degree += rotationIncrement * Double(foodItems.count * 5)
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            selectedFood = foodItems.randomElement()
//            let monsterImages = ["discomonster", "discomonster1", "discomonster2", "discomonster3", "discomonster4", "discomonster5"]
//            selectedMonsterImage = monsterImages.randomElement()
//        }
//    }
//}
//
//
//// 輪盤視圖
//struct WheelView: View {
//    @Binding var degree: Double
//    let array: [String]  // 類型名稱
//    let circleSize: Double
//    
//    var body: some View {
//        ZStack {
//            let anglePerCount = Double.pi * 2.0 / Double(array.count)
//            Circle().fill(
//                AngularGradient(gradient: Gradient(colors: [.orange, .yellow, .green, .blue, .purple, .pink]), center: .center)
//            )
//            .hueRotation(Angle(degrees: degree))
//            .frame(width: circleSize, height: circleSize)
//            .shadow(radius: 10)
//            .opacity(0.8)
//            
//            ForEach(0..<array.count, id: \.self) { index in
//                let angle = Double(index) * anglePerCount + degree * Double.pi / 180
//                let xOffset = CGFloat(circleSize / 2 - 50) * cos(angle)
//                let yOffset = CGFloat(circleSize / 2 - 50) * sin(angle)
//                Text("\(array[index].prefix(1).uppercased())") // 只顯示類別首字母
//                    .rotationEffect(Angle(degrees: -degree))
//                    .offset(x: xOffset, y: yOffset)
//                    .font(.system(size: 20, weight: .bold))
//                    .foregroundColor(.white)
//                    .shadow(radius: 2)
//            }
//        }
//        .frame(width: circleSize, height: circleSize)
//        .opacity(0.9)
//    }
//}
//
//// 自訂 Spin 按鈕
//struct SpinButton: View {
//    var action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Image(systemName: "arrow.2.circlepath.circle.fill")
//                    .font(.title2)
//                Text("Spin and Pick Food")
//                    .fontWeight(.semibold)
//                    .font(.title3)
//            }
//            .padding()
//            .foregroundColor(.white)
//            .background(
//                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
//            )
//            .cornerRadius(30)
//            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
//        }
//        .scaleEffect(1.0)
//        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: 1.0)
//    }
//}
//
//// 自訂 Reset 按鈕
//struct ResetButton: View {
//    var action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Image(systemName: "arrow.counterclockwise.circle.fill")
//                    .font(.title2)
//                Text("Reset")
//                    .fontWeight(.semibold)
//                    .font(.title3)
//            }
//            .padding()
//            .foregroundColor(.white)
//            .background(
//                LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing)
//            )
//            .cornerRadius(30)
//            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
//        }
//        .scaleEffect(1.0)
//        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: 1.0)
//    }
//}
//
//struct WhatToEatGameView_Previews: PreviewProvider {
//    static var previews: some View {
//        WhatToEatGameView()
//    }
//}

//MARK: -唯美的轉盤
//import SwiftUI
//
//struct myVal: Equatable {
//    let id = UUID()
//    let val: String
//}
//
//enum Direction {
//    case left
//    case right
//}
//
//struct WhatToEatGameView: View {
//    @State var degree = 90.0
//    let food = ["漢堡", "沙拉", "披薩", "義大利麵", "雞腿便當", "刀削麵", "火鍋", "牛肉麵", "關東煮"]
//    @State private var selectedFood: String?
//    let array: [myVal] = [
//        myVal(val: "小吃"),
//        myVal(val: "素食"),
//        myVal(val: "西式"),
//        myVal(val: "中式"),
//        myVal(val: "泰式"),
//        myVal(val: "日式"),
//        myVal(val: "韓式"),
//        myVal(val: "異國"),
//        myVal(val: "健康"),
//        myVal(val: "速食")
//    ]
//
//    var body: some View {
//        VStack {
//            ZStack(alignment: .center) {
//                Color.orange.opacity(0.4).ignoresSafeArea()
//                    .hueRotation(Angle(degrees: degree))
//                
//                WheelView(degree: $degree, array: array, circleSize: 400)
//                    .offset(y: -300)
//                    .shadow(color: .white, radius: 4, x: 0, y: 0)
//                
//                Image("Cutiemonster")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .padding(.top, 50)
//                
//                VStack(spacing: 30) {
//                    VStack {
//                        Text("Welcome to ")
//                            .fontWeight(.bold)
//                            .padding(.horizontal)
//                            .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
//                            .font(.custom("ArialRoundedMTBold", size: 25))
//                            .padding()
//                        
//                        Text("WHAT TO EAT")
//                            .fontWeight(.bold)
//                            .padding(.horizontal)
//                            .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.orange))
//                            .font(.custom("ArialRoundedMTBold", size: 30))
//                        
//                        Spacer()
//                        
//                        if selectedFood != .none {
//                            Text(selectedFood ?? "")
//                                .font(.largeTitle)
//                                .bold()
//                                .foregroundColor(.green)
//                                .id(selectedFood)
//                                .transition(.asymmetric(
//                                    insertion: .opacity.animation(.easeInOut(duration: 0.5).delay(0.2)),
//                                    removal: .opacity.animation(.easeInOut(duration: 0.4))
//                                ))
//                        }
//                        
//                        Button("Spin and Pick Food") {
//                            spinWheelAndPickFood()
//                        }
//                        .padding(.bottom, -15)
//                        
//                        Button("Reset") {
//                            selectedFood = .none
//                        }
//                        .buttonStyle(.bordered)
//                    }
//                    .padding()
//                    .frame(maxHeight: .infinity)
//                    .font(.title)
//                    .buttonStyle(.borderedProminent)
//                    .buttonBorderShape(.capsule)
//                    .controlSize(.large)
//                    .animation(.easeInOut(duration: 0.6), value: selectedFood)
//                }
//            }
//        }
//    }
//
//    func spinWheelAndPickFood() {
//        // 使輪盤旋轉到最後一項，增加動畫的持續時間來使旋轉變慢
//        let rotationIncrement = Double(360 / array.count)
//        withAnimation(.spring(response: 1.0, dampingFraction: 0.6, blendDuration: 1.0)) {
//            degree += rotationIncrement * Double(array.count - 1)
//        }
//        
//        // 隨機選擇一個食物，延遲顯示
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // 增加延遲時間
//            selectedFood = food.shuffled().first { $0 != selectedFood }
//        }
//    }
//}
//
//struct WheelView: View {
//    @Binding var degree: Double
//    let array: [myVal]
//    let circleSize: Double
//
//    var body: some View {
//        ZStack {
//            let anglePerCount = Double.pi * 2.0 / Double(array.count)
//            Circle().fill(EllipticalGradient(colors: [.orange, .yellow]))
//                .hueRotation(Angle(degrees: degree))
//            
//            ForEach(0..<array.count, id: \.self) { index in
//                let angle = Double(index) * anglePerCount
//                let xOffset = CGFloat(circleSize / 2 - 30) * cos(angle)
//                let yOffset = CGFloat(circleSize / 2 - 30) * sin(angle)
//                Text("\(array[index].val)")
//                    .rotationEffect(Angle(degrees: -degree))
//                    .offset(x: xOffset, y: yOffset)
//                    .font(.system(size: index == 0 ? 20 : 16)) // Highlight the 'chosen' index
//            }
//            .rotationEffect(Angle(degrees: degree))
//        }
//        .frame(width: circleSize, height: circleSize)
//    }
//}
//
//struct WhatToEatGameView_Previews: PreviewProvider {
//    static var previews: some View {
//        WhatToEatGameView()
//    }
//}

