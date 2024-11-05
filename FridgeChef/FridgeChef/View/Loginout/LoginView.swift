//
//  LoginView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct LoginView: View {
    @State private var isShowingLoginDetail = false
    @State private var isShowingSignUp = false
    @State private var scaleEffect1: CGFloat = 0.5
    @State private var opacityEffect1 = 0.0
    @State private var scaleEffect2: CGFloat = 1.0
    @State private var opacityEffect2 = 1.0
    @State private var offsetXEffect2: CGFloat = 0
    @ObservedObject var viewModel: RecipeSearchViewModel
    @ObservedObject var foodItemStore: FoodItemStore
    
    var body: some View {
        CustomNavigationBarView(title: "Welcome") {
            ZStack(alignment: .bottom) {
                GeometryReader { geometry in
                    ZStack {
                        Image("LetsCook")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .shadow(radius: 10)
                            .scaleEffect(scaleEffect1)
                            .opacity(opacityEffect1)
                            .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.2)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5)) {
                                    scaleEffect1 = 1.0
                                    opacityEffect1 = 1.0
                                }
                            }
                        
                        Image("himonster")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 500)
                            .shadow(radius: 10)
                            .scaleEffect(scaleEffect2)
                            .opacity(opacityEffect2)
                            .offset(x: offsetXEffect2)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .onAppear {
                                
                                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                    offsetXEffect2 = 30
                                }
                                
                                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    scaleEffect2 = 1.1
                                }
                                
                                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    opacityEffect2 = 0.9
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                VStack {
                    
                    Spacer()
                    
                    Button(action: {
                        self.isShowingLoginDetail = true
                    }, label: {
                        Text("Sign In")
                            .font(.custom("ArialRoundedMTBold", size: 19))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .opacity(0.8)
                            )
                            .cornerRadius(25)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                    })
                    
                    Button(action: {
                        self.isShowingSignUp = true
                    }, label: {
                        Text("Sign Up")
                            .font(.custom("ArialRoundedMTBold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)
                            )
                            .cornerRadius(25)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                    })
                    
                    // EULA Link
                    Link("End-User License Agreement (EULA)", destination: URL(string: "https://www.privacypolicies.com/live/3068621d-05a8-47a8-8321-28522fc642ed")!)
                        .font(.custom("ArialRoundedMTBold", size: 14))
                        .foregroundColor(.orange)
                        .padding(.top, 10)
                    
                }
                .sheet(isPresented: $isShowingLoginDetail) {
                    LoginDetailView()
                }
                .sheet(isPresented: $isShowingSignUp) {
                    SignUpView()
                }
            }
        }
    }
}
