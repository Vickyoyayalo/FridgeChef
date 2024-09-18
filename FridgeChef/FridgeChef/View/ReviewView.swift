//
//  ReviewView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct ReviewView: View {
    
    @Binding var isDisplayed: Bool
    @State private var showRatings = false
    
    var shoppingMarts: ShoppingMart
    
    var body: some View {
        ZStack {
            
            Image(shoppingMarts.image)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .ignoresSafeArea()
            
            Color.black
                .opacity(0.6)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
          
            HStack {
                Spacer()
                
                VStack {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.isDisplayed = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 30.0))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            
            VStack(alignment: .leading) {
                
                ForEach(ShoppingMart.Rating.allCases, id: \.self) { rating in
                    
                    HStack {
                        Image(rating.image)
                        Text(rating.rawValue.capitalized)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .opacity(showRatings ? 1.0 : 0)
                    .offset(x: showRatings ? 0 : 1000)
                    .animation(.easeOut.delay(Double(ShoppingMart.Rating.allCases.firstIndex(of: rating)!) * 0.05), value: showRatings)
                }
                
            }
            .onAppear {
                showRatings.toggle()
            }
        }
    }
}

#Preview {
ReviewView(isDisplayed: .constant(true), shoppingMarts: ShoppingMart(name: "Cafe Deadend", type: "Coffee & Tea Shop", location: "G/F, 72 Po Hing Fong, Sheung Wan, Hong Kong", phone: "232-923423", description: "Searching for great breakfast eateries and coffee?  Come over and enjoy a great meal.", image: "cafedeadend", isFavorite: true))
}

