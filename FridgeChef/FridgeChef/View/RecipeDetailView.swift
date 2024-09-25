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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Image(recipe.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Text(recipe.title)
                        .font(.largeTitle).bold()
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    Text("Ingredients:")
                        .font(.headline).bold()
                        .padding([.horizontal, .top])
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(recipe.ingredients, id: \.self) { ingredient in
                                Text(ingredient)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background( Color("NavigationBarTitle"))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 40)
                    
                    Text("Instructions:")
                        .font(.headline).bold()
                        .padding([.horizontal, .top])
                    
                    Text(recipe.instructions)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                    
                }
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Recipe Details")
            //            .navigationBarItems(trailing: Button(action: {
            //                dismiss()
            //            }) {
            //                Image(systemName: "xmark.circle.fill")
            //                    .foregroundColor(.orange)
            //                    .font(.title)
            //            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipe: Recipe(title: "烤雞沙拉", headline: "中餐",
                                        ingredients: ["雞胸肉", "混合蔬菜", "櫻桃番茄", "黃瓜", "巴薩米克醋醬"],
                                        instructions: "1.先將雞胸肉烤至熟透並帶有漂亮的烤痕。\n2.當雞肉在烤時，準備沙拉，將混合蔬菜洗淨並晾乾，櫻桃番茄切半，黃瓜切片。\n3.雞肉烤好後，讓它靜置幾分鐘再切片。\n4.在大碗中將蔬菜、番茄和黃瓜混合。\n5.將切片的烤雞放在沙拉上。\n6.淋上巴薩米克醋醬，輕輕攪拌均勻。\n7.你的美味又健康的烤雞沙拉已準備好享用！",
                                        imageName: "cask"))
        .preferredColorScheme(.light)
    }
}

