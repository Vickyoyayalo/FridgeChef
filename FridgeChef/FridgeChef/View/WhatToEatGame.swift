//
//  WhatToEatGame.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/25.
//
import SwiftUI

struct myVal: Equatable {
    let id = UUID()
    let val: String
}

enum Direction {
    case left
    case right
}

struct WhatToEatGameView: View {
    @State var degree = 90.0
        let array : [myVal] =  [myVal(val: "小吃"),
                                myVal(val: "素食"),
                                myVal(val: "西式"),
                                myVal(val: "中式"),
                                myVal(val: "泰式"),
                                myVal(val: "日式"),
                                myVal(val: "韓式"),
                                myVal(val: "異國"),
                                myVal(val: "健康"),
                                myVal(val: "速食")]
    

    var body: some View {
        VStack {
            
            ZStack(alignment: .center) {
                VStack {
                    Text("Welcome to ")
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
                        .font(.custom("ArialRoundedMTBold", size: 25))
                        .padding()
                    
                    Text("WAHT TO EAT")
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .font(.custom("ArialRoundedMTBold", size: 30))
                }
                
                Color.orange.opacity(0.4).ignoresSafeArea()
                    .hueRotation(Angle(degrees: degree))
                
                WheelView(degree: $degree, array: array, circleSize: 400)
                    .offset(y: -300)
                    .shadow(color: .white, radius: 4, x: 0, y: 0)
                
            }
           

            // Spin Button
            Button("Spin Wheel") {
                spinWheelManually()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }

    // Manual spin function
    func spinWheelManually() {
        // Simulate a left or right direction randomly
        let direction = Bool.random() ? Direction.left : Direction.right
        let rotationIncrement = Double(360 / array.count)
        let newDegree = direction == .left ? degree + rotationIncrement : degree - rotationIncrement
        withAnimation(.spring()) {
            degree = newDegree
        }
    }
}

struct WheelView: View {
    @Binding var degree: Double
    let array: [myVal]
    let circleSize: Double

    var body: some View {
        ZStack {
            let anglePerCount = Double.pi * 2.0 / Double(array.count)
            let drag = DragGesture()
                .onEnded { value in
                    let direction: Direction = value.startLocation.x > value.location.x + 10 ? .left : .right
                    moveWheel(direction)
                }
            // MARK: WHEEL STACK
            Circle().fill(EllipticalGradient(colors: [.orange, .yellow]))
                .hueRotation(Angle(degrees: degree))

            ForEach(0..<array.count, id: \.self) { index in
                let angle = Double(index) * anglePerCount
                let xOffset = CGFloat(circleSize / 2 - 30) * cos(angle)
                let yOffset = CGFloat(circleSize / 2 - 30) * sin(angle)
                Text("\(array[index].val)")
                    .rotationEffect(Angle(degrees: -degree))
                    .offset(x: xOffset, y: yOffset)
                    .font(.system(size: index == 0 ? 20 : 16)) // Highlight the 'chosen' index
            }
            .rotationEffect(Angle(degrees: degree))
            .gesture(drag)
        }
        .frame(width: circleSize, height: circleSize)
    }

    func moveWheel(_ direction: Direction) {
        let rotationIncrement = Double(360 / array.count)
        let newDegree = direction == .left ? degree + rotationIncrement : degree - rotationIncrement
        withAnimation(.spring()) {
            degree = newDegree
        }
    }
}

struct WhatToEatGameView_Previews: PreviewProvider {
    static var previews: some View {
        WhatToEatGameView()
    }
}

//import SwiftUI
//
//struct myVal : Equatable {
//    let id = UUID()
//    let val : String
//}
//
//enum Direction {
//    case left
//    case right
//}
//
//struct WhatToEatGameView: View {
//    @State var degree = 90.0
//    let array : [myVal] =  [myVal(val: "小吃"),
//                            myVal(val: "素食"),
//                            myVal(val: "西式"),
//                            myVal(val: "中式"),
//                            myVal(val: "泰式"),
//                            myVal(val: "日式"),
//                            myVal(val: "韓式"),
//                            myVal(val: "異國"),
//                            myVal(val: "健康"),
//                            myVal(val: "速食")]
//
//    var body: some View {
//        ZStack (alignment: .center){
//            Color.orange.opacity(0.4).ignoresSafeArea()
//                .hueRotation(Angle(degrees: degree))
//            
//            WheelView(degree: $degree, array: array, circleSize: 400)
//                .offset(y: -350)
//                .shadow(color: .white, radius: 4, x: 0, y: 0)
//        }
//    }
//}
//
//struct WheelView: View {
//    // Circle Radius
//    @State var radius : Double = 150
//    // Direction of swipe
//    @State var direction = Direction.left
//    // index of the number at the bottom of the circle
//    @State var chosenIndex = 0
//    // degree of circle and hue
//    @Binding var degree : Double
////    @State var degree = 90.0
//
//    let array : [myVal]
//    let circleSize : Double
//
//    func moveWheel() {
//        withAnimation(.spring()) {
//            if direction == .left {
//                degree += Double(360/array.count)
//                if chosenIndex == 0 {
//                    chosenIndex = array.count-1
//                } else {
//                    chosenIndex -= 1
//                }
//            } else {
//                degree -= Double(360/array.count)
//                if chosenIndex == array.count-1 {
//                    chosenIndex = 0
//                } else {
//                    chosenIndex += 1
//                }
//            }
//        }
//    }
//    
//    var body: some View {
//        ZStack {
//            let anglePerCount = Double.pi * 2.0 / Double(array.count)
//            let drag = DragGesture()
//                .onEnded { value in
//                    if value.startLocation.x > value.location.x + 10 {
//                        direction = .left
//                    } else if value.startLocation.x < value.location.x - 10 {
//                        direction = .right
//                    }
//                    moveWheel()
//                }
//            // MARK: WHEEL STACK - BEGINNING
//            ZStack {
//                Circle().fill(EllipticalGradient(colors: [.orange,.yellow]))
//                    .hueRotation(Angle(degrees: degree))
//
//                ForEach(0 ..< array.count) { index in
//                    let angle = Double(index) * anglePerCount
//                    let xOffset = CGFloat(radius * cos(angle))
//                    let yOffset = CGFloat(radius * sin(angle))
//                    Text("\(array[index].val)")
//                        .rotationEffect(Angle(degrees: -degree))
//                        .offset(x: xOffset, y: yOffset )
//                        .font(Font.system(chosenIndex == index ? .title : .body, design: .monospaced))
//                }
//            }
//            .rotationEffect(Angle(degrees: degree))
//            .gesture(drag)
//            .onAppear() {
//                radius = circleSize/2 - 30 // 30 is for padding
//            }
//            // MARK: WHEEL STACK - END
//        }
//        .frame(width: circleSize, height: circleSize)
//    }
//}
//
//#Preview(body: {
//    WhatToEatGameView()
//})
//
//import SwiftUI
//
//
//struct ContentView: View {
//    let food = ["漢堡", "沙拉", "披薩", "義大利麵", "雞腿便當", "刀削麵", "火鍋", "牛肉麵", "關東煮"]
//    @State private var selectedFood: String?
//    
//    var body: some View {
//        VStack(spacing: 30) {
//            Image("dinner")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//            
//            Text("今天吃什麼？")
//                .bold()
//            
//            if selectedFood != .none {
//                Text(selectedFood ?? "")
//                    .font(.largeTitle)
//                    .bold()
//                    .foregroundColor(.green)
//                    .id(selectedFood)
//                    .transition(.asymmetric(
//                        insertion: .opacity.animation(.easeInOut(duration: 0.5).delay(0.2)),
//                        
//                        removal: .opacity.animation(.easeInOut(duration: 0.4))))
//            }
//            
//            Button{
//                selectedFood = food.shuffled().first { $0 != selectedFood }
//            } label: {
//                Text(selectedFood == .none ? "告訴我" : "換一個").frame(width: 200)
//                    .animation(.none, value: selectedFood)
//                    .transformEffect(.identity)
//            }.padding(.bottom, -15)
//            
//            Button{
//                selectedFood = .none
//            } label: {
//                Text("重置").frame(width: 200)
//            }.buttonStyle(.bordered)
//        }
//        .padding()
//        .frame(maxHeight: .infinity)
//        .background(Color(.secondarySystemBackground))
//        .font(.title)
//        .buttonStyle(.borderedProminent)
//        .buttonBorderShape(.capsule)
//        .controlSize(.large)
//        .animation(.easeInOut(duration: 0.6), value: selectedFood)
//    }
//}
//
//#Preview {
//    ContentView()
//}

//MARK: FOODPICKER
//import SwiftUI
//
//
//struct ContentView: View {
//    let food = ["漢堡", "沙拉", "披薩", "義大利麵", "雞腿便當", "刀削麵", "火鍋", "牛肉麵", "關東煮"]
//    @State private var selectedFood: String?
//    
//    var body: some View {
//        VStack(spacing: 30) {
//            Image("dinner")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//            
//            Text("今天吃什麼？")
//                .bold()
//            
//            if selectedFood != .none {
//                Text(selectedFood ?? "")
//                    .font(.largeTitle)
//                    .bold()
//                    .foregroundColor(.green)
//                    .id(selectedFood)
//                    .transition(.asymmetric(
//                        insertion: .opacity.animation(.easeInOut(duration: 0.5).delay(0.2)),
//                        
//                        removal: .opacity.animation(.easeInOut(duration: 0.4))))
//            }
//            
//            Button{
//                selectedFood = food.shuffled().first { $0 != selectedFood }
//            } label: {
//                Text(selectedFood == .none ? "告訴我" : "換一個").frame(width: 200)
//                    .animation(.none, value: selectedFood)
//                    .transformEffect(.identity)
//            }.padding(.bottom, -15)
//            
//            Button{
//                selectedFood = .none
//            } label: {
//                Text("重置").frame(width: 200)
//            }.buttonStyle(.bordered)
//        }
//        .padding()
//        .frame(maxHeight: .infinity)
//        .background(Color(.secondarySystemBackground))
//        .font(.title)
//        .buttonStyle(.borderedProminent)
//        .buttonBorderShape(.capsule)
//        .controlSize(.large)
//        .animation(.easeInOut(duration: 0.6), value: selectedFood)
//    }
//}
//
//#Preview {
//    ContentView()
//}
