//
//  RecipeDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView{
            ScrollView {
                VStack(alignment: .leading) {
                    VStack {
                        Image(recipe.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .padding(10)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x:0, y: 4)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .padding()
                    
                    Text(recipe.headline)
                        .font(.title).bold()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Instructions:")
                                .font(.title3).bold()
                                .padding(.vertical, 5)
                            Text(recipe.instructions)
                                .font(.body)
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding()
                        
                        VStack(alignment: .leading) {
                            Text("Ingredients:")
                                .font(.title3).bold()
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: -20) {
                                    ForEach(Array(recipe.ingredients.enumerated()), id: \.element) { index, ingredinet in
                                        Text(ingredinet)
                                            .foregroundColor(.black.opacity(0.7))
                                            .padding(10)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(6)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .frame(height: 100)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                }
                .navigationTitle(recipe.title)
                .navigationBarItems(trailing: Image(systemName: "xmark.circle.fill")
//                    .resizable()
//                    .frame(width: 24, height: 24)
                    .foregroundColor(.orange)
                    .onTapGesture {
                        dismiss()
                    })
            }
        }
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipe: Recipe(title: "烤雞沙拉", headline: "中餐",
                                        ingredients: ["雞胸肉", "混合蔬菜", "櫻桃番茄", "黃瓜", "巴薩米克醋醬"],
                                        instructions: "1.先將雞胸肉烤至熟透並帶有漂亮的烤痕。\n2.當雞肉在烤時，準備沙拉，將混合蔬菜洗淨並晾乾，櫻桃番茄切半，黃瓜切片。\n3.雞肉烤好後，讓它靜置幾分鐘再切片。\n4.在大碗中將蔬菜、番茄和黃瓜混合。\n5.將切片的烤雞放在沙拉上。\n6.淋上巴薩米克醋醬，輕輕攪拌均勻。\n7.你的美味又健康的烤雞沙拉已準備好享用！",
                                        imageName: "chicken"))
        .preferredColorScheme(.light)
    }
}
