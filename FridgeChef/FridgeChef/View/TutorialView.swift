//
//  TutorialView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/8.
//

import SwiftUI

struct TutorialView: View {
    @ObservedObject var viewModel: RecipeSearchViewModel
    @ObservedObject var foodItemStore: FoodItemStore
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = false
    @State private var navigateToLogin: Bool = false
    
    let pageHeadings = [
        "TAKE CONTROL \nOF YOUR FRIDGE",
        "STAY AHEAD OF \nEXPIRATION DATES",
        "FIND RECIPES & \nSHOP EFFORTLESSLY",
        "SNAP & IDENTIFY \nINGREDIENTS",
        "COOK LIKE A PRO",
        "UNLOCK ENDLESS RECIPE IDEAS"
    ]
    
    let pageSubHeadings = [
        "Effortlessly track your fridge’s contents and avoid those ‘what's left?’ moments.",
        "Get instant alerts when food is about to expire, and whip up delicious meals with a few taps.",
        "Discover new recipes, add ingredients to your shopping cart, and get everything you need with one click.",
        "Use image recognition to identify ingredients instantly, and get cooking suggestions tailored to what's in your fridge.",
        "Snap a photo, and let FridgeChef GPT instantly guide you from ingredient to delicious dish.",
        "Plan your meals, add ingredients to your cart, and use our built-in supermarket navigator to get what you need, fast!"
    ]
    
    let pageImages = ["tutor1", "tutor2", "tutor3", "tutor4", "tutor5", "tutor6"]
    
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    TabView(selection: $currentPage) {
                        ForEach(pageHeadings.indices, id: \.self) { index in
                            TutorialPage(
                                image: pageImages[index],
                                heading: pageHeadings[index],
                                subHeading: pageSubHeadings[index]
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .animation(.default, value: currentPage)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            if currentPage < pageHeadings.count - 1 {
                                currentPage += 1
                            } else {
                                hasSeenTutorial = true
                                navigateToLogin = true
                            }
                        }, label: {
                            Text(currentPage == pageHeadings.count - 1 ? "GET STARTED" : "NEXT")
                                .font(.custom("Menlo-BoldItalic", size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .padding(.horizontal, 50)
                                .background(Color.customColor(named: "NavigationBarTitle"))
                                .cornerRadius(25)
                        })
                        
                        if currentPage < pageHeadings.count - 1 {
                            Button(action: {
                                hasSeenTutorial = true
                                navigateToLogin = true
                            }, label: {
                                Text("Skip")
                                    .font(.custom("Menlo-BoldItalic", size: 16))
                                    .foregroundColor(Color(.darkGray))
                            })
                        }
                    }
                    .padding(.bottom)
                }
                .navigationDestination(isPresented: $navigateToLogin) {
                    LoginView(viewModel: viewModel, foodItemStore: foodItemStore)
                }
            }
        }
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = .orange
        }
    }
}

#Preview {
    TutorialView(
        viewModel: RecipeSearchViewModel(),
        foodItemStore: FoodItemStore()
    )
}

struct TutorialPage: View {
    
    let image: String
    let heading: String
    let subHeading: String
    
    var body: some View {
        VStack(spacing: 70) {
            Image(image)
                .resizable()
                .scaledToFill()
            
            VStack(spacing: 10) {
                Text(heading)
                    .font(.custom("ArialRoundedMTBold", size: 18))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.bottom, 5)
                
                Text(subHeading)
                    .font(.custom("ArialRoundedMTBold", size: 16))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(minWidth: 300)
                    .padding(.top, 5)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top)
    }
}

#Preview("TutorialPage", traits: .sizeThatFitsLayout) {
    TutorialPage(image: "himonster", heading: "CREATE YOUR OWN FOOD GUIDE", subHeading: "Pin your favorite restaurants and create your own food guide")
}

