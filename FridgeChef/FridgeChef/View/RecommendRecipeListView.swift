//
//  ShoppingMartListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct RecommendRecipeListView: View {
    
    @State var recommendRecipes = [RecommendRecipe(name: "Petite Oyster", type: "法式料理", location: "香港上環太平山街24號 SOHO", phone: "983-284334", description: "這家生蠔吧提供從法國、澳洲、美國和日本進口的新鮮生蠔。", image: "petiteoyster", isFavorite: false),
                                   RecommendRecipe(name: "For Kee Restaurant", type: "麵包店", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "232-434222", description: "一個供應早餐和午餐的本地咖啡館，提供豬扒包、香港法式吐司等多種美食，營業時間從早上7點到下午4點半。", image: "forkee", isFavorite: false),
                                   RecommendRecipe(name: "Po's Atelier", type: "麵包店", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "234-834322", description: "一家專注於手工麵包和糕點的精品麵包店，融合了日本和斯堪的納維亞的靈感。", image: "posatelier", isFavorite: false),
                                   RecommendRecipe(name: "Bourke Street Backery", type: "巧克力", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "982-434343", description: "由優質食材、強勁咖啡、手工技術與勤奮工作創造出的靈魂美食，這使得 Bourke Street Bakery 聞名遐邇。", image: "bourkestreetbakery", isFavorite: false),
                                   RecommendRecipe(name: "Haigh's Chocolate", type: "咖啡館", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "734-232323", description: "來訪任何一家店，你都能品嚐巧克力、禮品包裝服務與個性化的服務。", image: "haigh", isFavorite: false),
                                   RecommendRecipe(name: "Palomino Espresso", type: "美式料理/海鮮", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "872-734343", description: "我們提供現場烘焙的糕點與三明治，是辦公人群的最愛。", image: "palomino", isFavorite: false),
                                   RecommendRecipe(name: "Upstate", type: "美式料理", location: "54 Frith Street London W1D 4SL United Kingdom",  phone: "343-233221", description: "這裡是鎮上最棒的海鮮餐廳，營業時間為下午5點到晚上10點半。", image: "upstate", isFavorite: false),
                                   RecommendRecipe(name: "Traif", type: "美式料理", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "985-723623", description: "一家以豬肉為主的美式餐廳，餐廳位於布魯克林，年輕人群居多，提供共食小盤料理，營業時間為晚上6點到11點。", image: "traif", isFavorite: false),
                                   RecommendRecipe(name: "Graham Avenue Meats", type: "早餐與早午餐", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong",  phone: "455-232345", description: "經典的意大利熟食店與肉鋪，供應充滿肉類的潛艇三明治。", image: "graham", isFavorite: false),
                                   RecommendRecipe(name: "Waffle & Wolf", type: "咖啡與茶", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong",  phone: "434-232322", description: "若你不吃麩質卻想吃鬆餅，這裡是你的不二選擇。", image: "waffleandwolf", isFavorite: false),
                                   RecommendRecipe(name: "Five Leaves", type: "咖啡與茶", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong", phone: "343-234553", description: "美食、雞尾酒、氛圍與服務皆優，招牌料理為瑞可塔煎餅。", image: "fiveleaves", isFavorite: false),
                                   RecommendRecipe(name: "Confessional", type: "西班牙料理", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong",  phone: "643-332323", description: "最美味的雞尾酒，供應各種高品質的國際靈感料理，含素食選項，營業時間為早上10點到晚上10點。", image: "confessional", isFavorite: false),
                                   RecommendRecipe(name: "Barrafina", type: "西班牙料理", location: "24 Tai Ping Shan Road SOHO, Sheung Wan, Hong Kong",  phone: "542-343434", description: "倫敦市中心最正宗的西班牙小吃酒吧系列！", image: "barrafina", isFavorite: false),
                                   RecommendRecipe(name: "Donostia", type: "西班牙料理", location: "英國倫敦塞摩爾廣場10號 W1H 7ND", phone: "722-232323", description: "極具創意且口味絕佳的巴斯克料理，氣氛輕鬆愉快。", image: "donostia", isFavorite: false),
                                   RecommendRecipe(name: "Royal Oak", type: "英式料理", location: "英國倫敦攝政街2號 SW1P 4BZ", phone: "343-988834", description: "自1872年以來的酒吧，提供傳統的炸魚薯條與 Young's 啤酒。", image: "royaloak", isFavorite: false),
                                   RecommendRecipe(name: "CASK Pub and Kitchen", type: "泰式料理", location: "英國倫敦查爾伍德街22號 Pimlico SW1V 2DY", phone: "432-344050", description: "我們提供美味的漢堡與泰國料理，每週一到週日營業，並且每週日有現場音樂。", image: "cask", isFavorite: false)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(recommendRecipes.indices, id: \.self) { index in
                    ZStack(alignment: .leading) {
                        NavigationLink(destination: RecommendRecipeDetailView(recommendRecipes: recommendRecipes[index])) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        BasicTextImageRow(recommendRecipes: $recommendRecipes[index])
                    }
                }
                .onDelete(perform: { indexSet in
                    recommendRecipes.remove(atOffsets: indexSet)
                })
                
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            
            .navigationTitle("FridgeChef")
            .navigationBarTitleDisplayMode(.automatic)
        }
        .tint(.white)
    }
}

#Preview {
    RecommendRecipeListView()
}

#Preview("Dark mode") {
    RecommendRecipeListView()
        .preferredColorScheme(.dark)
}

#Preview("BasicTextImageRow", traits: .sizeThatFitsLayout) {
    BasicTextImageRow(recommendRecipes: .constant(RecommendRecipe(name: "Cafe Deadend", type: "Coffee & Tea Shop", location: "G/F, 72 Po Hing Fong, Sheung Wan, Hong Kong", phone: "232-923423", description: "We offer espresso and espresso based drink, such as capuccino, cafe latte, piccolo and many more. Come over and enjoy a great meal.", image: "cafedeadend", isFavorite: true)))
}

#Preview("FullImageRow", traits: .sizeThatFitsLayout) {
    FullImageRow(imageName: "cafedeadend", name: "Cafe Deadend", type: "Cafe", location: "Hong Kong", isFavorite: .constant(true))
}

struct BasicTextImageRow: View {
    // MARK: - Binding
    
    @Binding var recommendRecipes: RecommendRecipe
    
    // MARK: - State variables
    
    @State private var showOptions = false
    @State private var showError = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Image(recommendRecipes.image ?? "defaultImage")
                .resizable()
                .frame(width: 120, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(alignment: .leading) {
                Text(recommendRecipes.name)
                    .font(.system(.title2, design: .rounded))
                
                Text(recommendRecipes.type)
                    .font(.system(.body, design: .rounded))
                
                Text(recommendRecipes.location)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.gray)
            }
            
            if recommendRecipes.isFavorite {
                Spacer()
                
                Image(systemName: "heart.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .contextMenu {
            Button(action: {
                self.showError.toggle()
            }) {
                HStack {
                    Text("Reserve a table")
                    Image(systemName: "phone")
                }
            }
            
            Button(action: {
                self.recommendRecipes.isFavorite.toggle()
            }) {
                HStack {
                    Text(recommendRecipes.isFavorite ? "Remove from favorites" : "Mark as favorite")
                    Image(systemName: "heart")
                }
            }
            
            Button(action: {
                self.showOptions.toggle()
            }) {
                HStack {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .alert("Not yet available", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text("Sorry, this feature is not available yet. Please retry later.")
        }
        .sheet(isPresented: $showOptions) {
            
            let defaultText = "Just checking in at \(recommendRecipes.name)"
            
            if let imageToShare = UIImage(named: recommendRecipes.image ?? "defaultImage") {
                ActivityView(activityItems: [defaultText, imageToShare])
            } else {
                ActivityView(activityItems: [defaultText])
            }
        }
    }
}

struct FullImageRow: View {
    
    var imageName: String
    var name: String
    var type: String
    var location: String
    
    @Binding var isFavorite: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.system(.title2, design: .rounded))
                    
                    Text(type)
                        .font(.system(.body, design: .rounded))
                    
                    Text(location)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.gray)
                }
                
                if isFavorite {
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.yellow)
                }
                
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}


