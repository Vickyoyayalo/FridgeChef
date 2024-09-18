//
//  Recipe.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation

struct Recipe: Identifiable {
    var id = UUID()
    var title: String
    var headline: String
    var ingredients: [String]
    var instructions: String
    var imageName: String
}

class RecipeManager:  ObservableObject {
    @Published var recipes: [Recipe] = [
        Recipe(title: "瑪格麗塔披薩", headline: "午餐",
                      ingredients: ["披薩麵團", "番茄", "新鮮莫扎里拉奶酪", "羅勒", "橄欖油"],
                      instructions: "1.首先將烤箱預熱到最高溫度。\n2.將披薩麵團擀成你想要的形狀。\n3.在麵團上塗抹一層薄薄的壓碎番茄，留出邊緣。\n4.把新鮮的莫扎里拉奶酪撕成小塊，均勻地撒在番茄上。\n5.在披薩上撒上新鮮的羅勒葉。\n6.淋上少許橄欖油。\n7.將披薩放在預熱好的披薩石或烤盤上，烘烤約10-12分鐘，直到餅皮呈金黃色，奶酪變得氣泡。\n8.從烤箱中取出，稍微冷卻後享用你的自製瑪格麗塔披薩。",
                      imageName: "pizza"),

        Recipe(title: "烤雞沙拉", headline: "中餐",
               ingredients: ["雞胸肉", "混合蔬菜", "櫻桃番茄", "黃瓜", "巴薩米克醋醬"],
               instructions: "1.先將雞胸肉烤至熟透並帶有漂亮的烤痕。\n2.當雞肉在烤時，準備沙拉，將混合蔬菜洗淨並晾乾，櫻桃番茄切半，黃瓜切片。\n3.雞肉烤好後，讓它靜置幾分鐘再切片。\n4.在大碗中將蔬菜、番茄和黃瓜混合。\n5.將切片的烤雞放在沙拉上。\n6.淋上巴薩米克醋醬，輕輕攪拌均勻。\n7.你的美味又健康的烤雞沙拉已準備好享用！",
               imageName: "chicken"),

        Recipe(title: "蔬菜炒豆腐", headline: "晚餐",
               ingredients: ["各種蔬菜", "豆腐", "醬油", "薑", "大蒜", "芝麻油"],
               instructions: "1.先準備好蔬菜，清洗並切成小塊。\n2.按壓豆腐去除多餘水分，然後切成方塊。\n3.在炒鍋或大平底鍋中，中火加熱一些芝麻油。\n4.加入薑和大蒜，炒香。\n5.加入豆腐，翻炒至金黃且略帶酥脆。\n6.加入切好的蔬菜，繼續翻炒，直到蔬菜變軟但仍略帶脆感。\n7.倒入一些醬油調味，將所有材料拌勻。\n8.五彩繽紛的蔬菜炒豆腐已經可以上桌了。可搭配米飯或麵條享用！",
               imageName: "stir_fry"),

        Recipe(title: "烤三文魚", headline: "晚餐",
               ingredients: ["三文魚片", "檸檬", "蒔蘿", "大蒜", "橄欖油"],
               instructions: "1.將烤箱預熱至375°F（190°C）。\n2.將三文魚片放在鋪有烤紙的烤盤上。\n3.淋上橄欖油，並抹上切碎的大蒜和蒔蘿。\n4.將檸檬切成薄片，放在三文魚上。\n5.加入鹽和胡椒調味。\n6.將三文魚放入預熱好的烤箱中，烘烤約12-15分鐘，直到用叉子輕易撥開魚肉。\n7.搭配你喜愛的配菜，享受這道營養豐富的烤三文魚晚餐吧！",
               imageName: "salmon"),

        Recipe(title: "家常燉牛肉", headline: "晚餐",
               ingredients: ["牛肉燉肉塊", "馬鈴薯", "胡蘿蔔", "洋蔥", "牛肉湯", "百里香"],
               instructions: "1.將牛肉燉塊切成小塊，並用鹽和胡椒調味。\n2.在大鍋中加熱一些油，將牛肉四面煎至金黃，然後取出。\n3.在同一鍋中加入切碎的洋蔥，煸炒至透明。\n4.加入切好的胡蘿蔔和馬鈴薯，攪拌幾分鐘。\n5.將煎好的牛肉放回鍋中，倒入足夠的牛肉湯覆蓋所有材料。\n6.加入幾根百里香以增添風味。\n7.蓋上鍋蓋，將燉鍋用小火煮約1.5至2小時，直到牛肉變得軟嫩，味道融合。\n8.端上這道豐盛的家常燉牛肉，搭配脆皮麵包，享受這充滿安慰的美味吧！",
               imageName: "beef"),

        Recipe(title: "卡普雷塞沙拉", headline: "午餐",
               ingredients: ["番茄", "新鮮莫扎里拉奶酪", "羅勒", "巴薩米克釉", "橄欖油"],
               instructions: "1.將番茄和新鮮的莫扎里拉奶酪切成相同厚度的圓片。\n2.將番茄和莫扎里拉奶酪片交替排列在盤子上，略微重疊。\n3.將新鮮的羅勒葉夾在番茄和莫扎里拉奶酪片之間。\n4.淋上巴薩米克釉和橄欖油。\n5.撒上一些鹽和現磨黑胡椒調味。\n6.這道卡普雷塞沙拉簡單且味道鮮美，是一道完美的開胃菜或輕食午餐，展現了番茄、莫扎里拉和羅勒的絕佳搭配。",
               imageName: "salad")
    ]
}
