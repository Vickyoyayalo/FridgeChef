//
//  ChatView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/10.
//

import SwiftUI
import PhotosUI
import Vision
import CoreML
import IQKeyboardManagerSwift

struct Message: Identifiable {
    var id: UUID = UUID()
    let role: ChatGPTRole
    let content: String?
    let image: UIImage?
}

enum ChatGPTRole: String {
    case system
    case user
    case assistant
}

struct PlaceholderTextEditor: View {
    @Binding var text: String
    var placeholder: String

    @State private var dynamicHeight: CGFloat = 44  // 设置初始高度
    
    var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight < 100 ? dynamicHeight : 100)  // 控制高度变化和滚动
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .onChange(of: text) { _ in
                    calculateHeight()  // 每当文本改变时重新计算高度
                }

            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
    }
    
    // 动态计算高度
    private func calculateHeight() {
        let maxSize = CGSize(width: UIScreen.main.bounds.width - 32, height: .infinity)
        let size = CGSize(width: maxSize.width, height: CGFloat.greatestFiniteMagnitude)
        
        let text = self.text.isEmpty ? " " : self.text  // 避免计算为空文本
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17)]
        let rect = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        DispatchQueue.main.async {
            self.dynamicHeight = rect.height + 24  // 根据文本计算高度并增加 padding
        }
    }
}


struct ChatView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var isFetchingLink: Bool = false
    @State private var isWaitingForResponse = false
    @State private var parsedRecipes: [UUID: ParsedRecipe] = [:]
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var image: UIImage?
    @State private var showChangePhotoDialog = false
    @State private var errorMessage: String?
    @State private var api = ChatGPTAPI(
        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA",
        systemPrompt: """
        你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。每次回覆時，請務必提供食譜名稱與完整的【食材】清單，並附上一個該指定食譜的有效網址。如果無法提供有效網址，請明確說明無法提供，另外你也能依據使用者的想法推薦相關食譜詳細做法，並依照使用著使用的語言做修改與回答。

        🥙 食譜名稱：中文名稱 (英文名稱) （請務必同時提供中文和英文的食譜名稱。如果沒有英文名稱，請使用拼音或直接重複中文名稱。）

        🥬【食材】（必須提供所有食材，並包含數量和單位，格式為：數量 單位 食材名稱）
        • 2 個 蘋果
        • 1 杯 牛奶
        • ...

        🍳【烹飪步驟】（（詳細描述每個步驟，每個步驟以數字和句點開頭，直接描述，不要添加額外的標題、粗體字、冒號或其他符號，詳細描述每個步驟）
        1. 步驟一
        2. 步驟二
        3. 步驟三
        ...

        🔗【食譜連結】
        (請提供一個與使用者提問的食譜相關的有效網址。)

        👩🏻‍🍳【貼心提醒】
        (這裡可以貼心提醒或是回答使用者的問題。)
        Bon appetit 🍽️
        
        **注意事項：**
        - **如果使用者使用英文問答，請全部改以英文格式與內容回覆。**
        - **請勿在步驟中添加額外的標題、粗體字、冒號或其他符號。**
        - **每個步驟應該是完整的句子，直接描述操作。**
        - **嚴格按照上述格式回覆，不要添加任何額外的內容或改變格式。**

        """
    )
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 漸層背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
              
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        IQKeyboardManager.shared.resignFirstResponder()
                    }
                
                VStack {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Image("LogoFridgeChef")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 38)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(messages) { message in
                                messageView(for: message)
                            }
                        }
                    }
                    
                    if isWaitingForResponse {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color.clear)
                    }
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(15)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .onTapGesture {
                                self.showChangePhotoDialog = true
                            }
                            .confirmationDialog("想換張照片嗎？", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
                                Button("換一張") {
                                    showPhotoOptions = true
                                }
                                Button("移除照片", role: .destructive) {
                                    self.image = nil
                                }
                                Button("取消", role: .cancel) {}
                            }
                    }
                    HStack {
                        Button(action: { showPhotoOptions = true }) {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit() // Ensure the image scales properly within the frame
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        }
                        .padding(.leading, 10)
                        .fixedSize() // Prevent the button from being compressed
                        .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                            Button("Camera") { photoSource = .camera }
                            Button("Photo Library") { photoSource = .photoLibrary }
                        }
                        
                        Spacer(minLength: 20) // Ensures space distribution
                        
                        PlaceholderTextEditor(text: $inputText, placeholder: "Want ideas? 🥙 ...")
                            .frame(maxHeight: 100) // Consistent height with buttons
                        
                        Spacer(minLength: 20) // Ensures space distribution
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        }
                        .padding(.trailing, 10)
                        .fixedSize() // Prevent the button from being compressed
                    }
                    .padding(.horizontal)
                }
                .fullScreenCover(item: $photoSource) { source in
                    ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
        
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("Failed to load model")
            completion("未知食材")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No results: \(error?.localizedDescription ?? "Unknown error")")
                completion("未知食材")
                return
            }
            
            DispatchQueue.main.async {
                let label = topResult.identifier
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "未知食材"
                completion(translatedLabel)
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("Unable to create \(CIImage.self) from \(image).")
            completion("未知食材")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
                completion("未知食材")
            }
        }
    }
    
    func parseRecipe(from message: String) -> ParsedRecipe {
        var title: String?
        var ingredients: [ParsedIngredient] = []
        var steps: [String] = []
        var link: String?
        var tips: String?
        var unparsedContent: String? = ""
        
        let lines = message.components(separatedBy: "\n")
        var currentSection: String?
        
        var isParsed = false
        
        func processIngredientsLine(_ line: String) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "")
            if !trimmedLine.isEmpty {
                let pattern = #"^(\d+\.?\d*)\s*([^\d\s]+)?\s+(.+)$"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: trimmedLine, options: [], range: NSRange(location: 0, length: trimmedLine.utf16.count)) {
                    
                    let quantityRange = Range(match.range(at: 1), in: trimmedLine)
                    let unitRange = Range(match.range(at: 2), in: trimmedLine)
                    let nameRange = Range(match.range(at: 3), in: trimmedLine)
                    
                    let quantityString = quantityRange.map { String(trimmedLine[$0]) } ?? "1.0"
                    let quantityDouble = Double(quantityString) ?? 1.0
                    let unit = unitRange.map { String(trimmedLine[$0]) } ?? "unit"
                    let name = nameRange.map { String(trimmedLine[$0]) } ?? trimmedLine
                    
                    // 設置一個默認的 expirationDate，例如 5 天後
                    let expirationDate = Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date()
                    
                    ingredients.append(ParsedIngredient(name: name, quantity: quantityDouble, unit: unit, expirationDate: expirationDate))
                } else {
                    // 如果无法解析，设置默认的 quantity 和 expirationDate
                    ingredients.append(ParsedIngredient(name: trimmedLine, quantity: 1.0, unit: "unit", expirationDate: Calendar.current.date(byAdding: .day, value: 0, to: Date()) ?? Date()))
                }
            }
        }

        
        func processStepsLine(_ line: String) {
            var trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                trimmedLine = removeLeadingNumber(from: trimmedLine)
                steps.append(trimmedLine)
            }
        }
        
        func processLinkLine(_ line: String) {
            if let urlRange = line.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
                link = String(line[urlRange])
            } else {
                // 如果无法提取链接，检查是否有提示无法提供链接的文本
                if line.contains("無法提供") || line.contains("抱歉") {
                    link = nil
                } else {
                    // 如果有其他文本，可能是一个 URL，但没有以 http 开头，尝试补全
                    let potentialLink = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !potentialLink.isEmpty {
                        link = "https://" + potentialLink
                    } else {
                        link = nil
                    }
                }
            }
        }
        
        func processTipsLine(_ line: String) {
            tips = (tips ?? "") + line + "\n"
        }
        
        // 主循环
        for line in lines {
            if line.contains("🥙") {
                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cleanedLine = cleanedLine.replacingOccurrences(of: "食譜名稱：", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

                // Check for both Chinese and English names
                if let range = cleanedLine.range(of: #"(.+)\s*\((.+)\)"#, options: .regularExpression) {
                    let chineseName = String(cleanedLine[range.lowerBound..<cleanedLine.range(of: "(")!.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let englishName = String(cleanedLine[cleanedLine.range(of: "(")!.upperBound..<cleanedLine.range(of: ")")!.lowerBound]).trimmingCharacters(in: .whitespaces)
                    title = "\(chineseName) (\(englishName))"
                } else {
                    title = cleanedLine
                }

                isParsed = true
                continue
            }

            if line.contains("【食材】") {
                currentSection = "ingredients"
                isParsed = true
                continue
            }
            if line.contains("【烹飪步驟】") {
                currentSection = "steps"
                isParsed = true
                continue
            }
            if line.contains("【食譜連結】") {
                currentSection = "link"
                isParsed = true
                continue
            }
            if line.contains("【貼心提醒】") {
                currentSection = "tips"
                isParsed = true
                continue
            }
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            switch currentSection {
            case "ingredients":
                processIngredientsLine(line)
            case "steps":
                processStepsLine(line)
            case "link":
                processLinkLine(line)
            case "tips":
                processTipsLine(line)
            default:
                unparsedContent? += line + "\n"
            }
        }
        
        tips = tips?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果未成功解析，则将整个消息内容作为未解析内容
        if !isParsed {
            unparsedContent = message
        }
        
        print("Parsed Recipe: \(ParsedRecipe(title: title, ingredients: ingredients, steps: steps, link: link, tips: tips))")
        
        return ParsedRecipe(title: title, ingredients: ingredients, steps: steps, link: link, tips: tips, unparsedContent: unparsedContent)
    }
    
    func removeLeadingNumber(from string: String) -> String {
        let pattern = #"^\s*\d+[\.\、]?\s*"#  // 匹配数字后跟 "."、"、" 或空格
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(string.startIndex..., in: string)
            return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        } else {
            return string
        }
    }
    
    private func messageView(for message: Message) -> some View {
        let messageId = message.id
        
        return HStack {
            if let recipe = parsedRecipes[messageId] {
                // 已解析的訊息
                if message.role == .user {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let image = message.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                        }
                        if let content = message.content {
                            Text(content)
                                .padding()
                                .background(Color.customColor(named: "NavigationBarTitle"))
                                .foregroundColor(.white)
                                .bold()
                                .cornerRadius(10)
                        }
                    }
                } else {
                    // 顯示已解析的食譜內容
                    VStack(alignment: .leading, spacing: 10) {
                        // 顯示食譜名稱
                        if let title = recipe.title {
                            Text(" \(title) 🥙")
                                .font(.title3)
                                .bold()
                                .padding(.bottom, 5)
                        }
                        
                        // 顯示食材列表
                        if !recipe.ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🥬【食材】")
                                    .font(.headline)
                                ForEach(recipe.ingredients, id: \.name) { ingredient in
                                    IngredientRow(ingredient: ingredient, addAction: addIngredientToShoppingList)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // 顯示烹飪步驟
                        if !recipe.steps.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🍳【烹飪步驟】")
                                    .font(.headline)
                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .bold()
                                        Text(step)
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.3))
                            .cornerRadius(10)
                        }
                        
                        // 顯示食譜連結
                        if let link = recipe.link, let url = URL(string: link) {
                            Link(destination: url) {
                                HStack {
                                    Text("🔗 查看完整食譜")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        } else {
                            Text("抱歉，我目前無法提供該料理的食譜連結。如果您有任何其他食材或菜式需要幫忙，歡迎隨時告訴我！讓我來幫助您找到更多美味的食譜。👨🏻‍🌾")
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        // 顯示貼心提醒
                        if let tips = recipe.tips {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("👩🏻‍🍳【貼心提醒】")
                                    .font(.headline)
                                Text(tips)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    Spacer()
                }
            } else {
                // 未解析的訊息
                if message.role == .user {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let image = message.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                        }
                        if let content = message.content {
                            Text(content)
                                .padding()
                                .background(Color.customColor(named: "NavigationBarTitle"))
                                .foregroundColor(.white)
                                .bold()
                                .cornerRadius(10)
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        if let content = message.content {
                            Text(content)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }

    
    func fetchRecipeLink(recipeName: String) async -> String? {
        let service = RecipeSearchService()
        return await withCheckedContinuation { continuation in
            service.searchRecipes(query: recipeName, maxFat: nil) { result in
                switch result {
                case .success(let response):
                    if let firstRecipe = response.results.first {
                        // 获取食谱详情，包含 sourceUrl
                        service.getRecipeInformation(recipeId: firstRecipe.id) { detailResult in
                            switch detailResult {
                            case .success(let details):
                                continuation.resume(returning: details.sourceUrl)
                            case .failure(let error):
                                print("Error fetching recipe details: \(error)")
                                continuation.resume(returning: nil)
                            }
                        }
                    } else {
                        print("No recipes found for \(recipeName)")
                        continuation.resume(returning: nil)
                    }
                case .failure(let error):
                    print("Error searching recipes: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func removeIngredientsSection(from message: String) -> String {
        var lines = message.components(separatedBy: "\n")
        var newLines: [String] = []
        var isIngredientSection = false
        
        for line in lines {
            if line.contains("【食材】") {
                isIngredientSection = true
                continue
            } else if line.contains("【烹飪步驟】") || line.contains("🍳") {
                isIngredientSection = false
            }
            
            if !isIngredientSection {
                newLines.append(line)
            }
        }
        return newLines.joined(separator: "\n")
    }
    
    func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
        let newFoodItem = FoodItem(
            id: UUID(),
            name: ingredient.name,
            quantity: ingredient.quantity, // 直接使用 Double，不進行轉換
            unit: ingredient.unit,
            status: .toBuy, // 直接使用 .toBuy，不透過 rawValue
            daysRemaining: Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: ingredient.expirationDate).day ?? 0,
            expirationDate: ingredient.expirationDate, // 設置 expirationDate
            image: nil
        )

        if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
            foodItemStore.foodItems.append(newFoodItem)
            return true
        } else {
            return false
        }
    }

    
    func extractIngredients(from message: String) -> [String] {
        var ingredients: [String] = []
        let lines = message.components(separatedBy: "\n")
        var isIngredientSection = false
        
        for line in lines {
            if line.contains("【食材】") {
                isIngredientSection = true
                continue
            } else if line.contains("【烹飪步驟】") || line.contains("🍳") {
                break
            }
            
            if isIngredientSection {
                // 移除前面的符号和空格
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "")
                if !trimmedLine.isEmpty {
                    ingredients.append(trimmedLine)
                }
            }
        }
        return ingredients
    }
    
    
    func sendMessage() {
        // 檢查輸入文本和圖片是否為空
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else { return }
        
        let messageText = inputText
        let messageImage = image
        
        inputText = ""
        image = nil
        
        if let messageImage = messageImage {
            let imageMessage = Message(role: .user, content: nil, image: messageImage)
            self.messages.append(imageMessage)
        }
        
        if !messageText.isEmpty {
            let userMessage = Message(role: .user, content: messageText, image: nil)
            self.messages.append(userMessage)
        }
        
        isWaitingForResponse = true
        
        Task {
            do {
                var finalMessageText = messageText
                
                if let messageImage = messageImage {
                    // 進行食材識別
                    recognizeFood(in: messageImage) { recognizedText in
                        DispatchQueue.main.async {
                            // 將識別結果添加到訊息文本
                            if !finalMessageText.isEmpty {
                                finalMessageText += "\n識別的食材：\(recognizedText)。\n請提供詳細的食譜和烹飪步驟。"
                            } else {
                                finalMessageText = "識別的食材：\(recognizedText)。\n請提供詳細的食譜和烹飪步驟。"
                            }
                            
                            // 更新使用者訊息
                            if !finalMessageText.isEmpty {
                                let updatedUserMessage = Message(role: .user, content: finalMessageText, image: nil)
                                self.messages.append(updatedUserMessage)
                            }
                            
                            // 發送訊息給 API
                            Task {
                                do {
                                    let responseText = try await api.sendMessage(finalMessageText)
                                    let responseMessage = Message(role: .assistant, content: responseText, image: nil)
                                    DispatchQueue.main.async {
                                        self.messages.append(responseMessage)
                                        self.errorMessage = nil
                                        self.isWaitingForResponse = false
                                    }
                                    
                                    // 解析食譜並獲取連結
                                    if let responseContent = responseMessage.content {
                                        var parsedRecipe = parseRecipe(from: responseContent)
                                        if parsedRecipe.link == nil, let title = parsedRecipe.title {
                                            if let link = await fetchRecipeLink(recipeName: title) {
                                                parsedRecipe.link = link
                                            }
                                        }
                                        DispatchQueue.main.async {
                                            self.parsedRecipes[responseMessage.id] = parsedRecipe
                                        }
                                    }
                                } catch {
                                    print("發送訊息時出錯：\(error)")
                                    DispatchQueue.main.async {
                                        self.errorMessage = "發送訊息時出錯：\(error.localizedDescription)"
                                        self.isWaitingForResponse = false
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // 沒有圖片，直接發送訊息
                    if !finalMessageText.isEmpty {
                        let responseText = try await api.sendMessage(finalMessageText)
                        let responseMessage = Message(role: .assistant, content: responseText, image: nil)
                        DispatchQueue.main.async {
                            self.messages.append(responseMessage)
                            self.errorMessage = nil
                            self.isWaitingForResponse = false
                        }
                        
                        // 解析食譜並獲取連結
                        if let responseContent = responseMessage.content {
                            var parsedRecipe = parseRecipe(from: responseContent)
                            
//                            // 任何情況下都從 Spoonacular API 獲取連結
                            if let title = parsedRecipe.title {
                                if let link = await fetchRecipeLink(recipeName: title) {
                                    parsedRecipe.link = link
                                }
                            }
                            
//                            
//                            當助理的回覆沒有提供連結時（即 parsedRecipe.link == nil），程式會嘗試從 Spoonacular API 獲取連結。
//                            if parsedRecipe.link == nil, let title = parsedRecipe.title {
//                                if let link = await fetchRecipeLink(recipeName: title) {
//                                    parsedRecipe.link = link
//                                }
//                            }
                            
                            DispatchQueue.main.async {
                                self.parsedRecipes[responseMessage.id] = parsedRecipe
                            }
                        }
                    }
                }
            } catch {
                print("發送訊息時出錯：\(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "發送訊息時出錯：\(error.localizedDescription)"
                    self.isWaitingForResponse = false
                }
            }
        }
    }

    
    func sendMessageToAPI(message: String) {
        Task {
            do {
                let responseText = try await api.sendMessage(message)
                DispatchQueue.main.async {
                    self.messages.append(Message(role: .assistant, content: responseText, image: nil))
                    self.isWaitingForResponse = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "發送訊息出錯：\(error.localizedDescription)"
                    self.isWaitingForResponse = false
                }
            }
        }
    }
    
    func processAssistantResponse(_ responseMessage: Message) async {
        if let responseContent = responseMessage.content {
            var parsedRecipe = parseRecipe(from: responseContent)

            if var title = parsedRecipe.title {
                // If the title is in Chinese, translate it to English
                if isChinese(text: title) {
                    // Use your translation function to get the English title
                    let translatedTitle = await withCheckedContinuation { continuation in
                        translate(text: title, from: "zh", to: "en") { translatedText in
                            continuation.resume(returning: translatedText)
                        }
                    }
                    if let translatedTitle = translatedTitle {
                        title = translatedTitle
                    }
                }
                // Fetch the link from Spoonacular API using the English title
                if let link = await fetchRecipeLink(recipeName: title) {
                    parsedRecipe.link = link
                } else {
                    // Handle the case where no link is found
                    parsedRecipe.link = nil
                }
            }

            DispatchQueue.main.async {
                self.parsedRecipes[responseMessage.id] = parsedRecipe
            }
        }
    }

    func isChinese(text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }

}

struct IngredientRow: View {
    var ingredient: ParsedIngredient
    var addAction: (ParsedIngredient) -> Bool
    @EnvironmentObject var foodItemStore: FoodItemStore

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        let isAdded = foodItemStore.foodItems.contains { $0.name.lowercased() == ingredient.name.lowercased() }

        Button(action: {
            if !isAdded {
                let success = addAction(ingredient)
                alertMessage = success ? "\(ingredient.name) add to your Grocery List 🛒" : "\(ingredient.name) already exists!"
                print("Added \(ingredient.name): \(success)") // Debug
            } else {
                alertMessage = "\(ingredient.name) already exists."
                print("\(ingredient.name) already exists.") // Debug
            }
            showAlert = true
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(ingredient.name)
                        .foregroundColor(isAdded ? .gray : Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .bold()
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    if ingredient.quantity > 0 { // 改為檢查 quantity > 0
                        Text("Qty：\(ingredient.quantity, specifier: "%.2f") \(ingredient.unit)") // 格式化為兩位小數
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: isAdded ? "checkmark.circle.fill" : "cart.badge.plus.fill")
                    .foregroundColor(isAdded ? .green : Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAdded)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Added to your Grocery List!"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Sure"))
            )
        }
    }
}

extension Color {
    static func customColor(named name: String) -> Color {
        return Color(UIColor(named: name) ?? .systemRed)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}


//MARK: -Good
////
////  ChatView.swift
////  FridgeChef
////
////  Created by Vickyhereiam on 2024/9/10.
////
//
//import SwiftUI
//import PhotosUI
//import Vision
//import CoreML
//import IQKeyboardManagerSwift
//
//struct Message: Identifiable {
//    var id: UUID = UUID()
//    let role: ChatGPTRole
//    let content: String?
//    let image: UIImage?
//}
//
//enum ChatGPTRole: String {
//    case system
//    case user
//    case assistant
//}
//
//struct PlaceholderTextEditor: View {
//    @Binding var text: String
//    var placeholder: String
//
//    @State private var dynamicHeight: CGFloat = 44  // 设置初始高度
//    
//    var body: some View {
//        ZStack(alignment: .leading) {
//            TextEditor(text: $text)
//                .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight < 100 ? dynamicHeight : 100)  // 控制高度变化和滚动
//                .padding(8)
//                .background(Color.white)
//                .cornerRadius(10)
//                .shadow(radius: 3)
//                .onChange(of: text) { _ in
//                    calculateHeight()  // 每当文本改变时重新计算高度
//                }
//
//            if text.isEmpty {
//                Text(placeholder)
//                    .foregroundColor(.gray)
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 12)
//                    .allowsHitTesting(false)
//            }
//        }
//    }
//    
//    // 动态计算高度
//    private func calculateHeight() {
//        let maxSize = CGSize(width: UIScreen.main.bounds.width - 32, height: .infinity)
//        let size = CGSize(width: maxSize.width, height: CGFloat.greatestFiniteMagnitude)
//        
//        let text = self.text.isEmpty ? " " : self.text  // 避免计算为空文本
//        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17)]
//        let rect = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
//        
//        DispatchQueue.main.async {
//            self.dynamicHeight = rect.height + 24  // 根据文本计算高度并增加 padding
//        }
//    }
//}
//
//
//struct ChatView: View {
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var isFetchingLink: Bool = false
//    @State private var isWaitingForResponse = false
//    @State private var parsedRecipes: [UUID: ParsedRecipe] = [:]
//    @State private var api = ChatGPTAPI(
//        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA",
//        systemPrompt: """
//        你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。每次回覆時，請務必提供食譜名稱與完整的【食材】清單，並附上一個該指定食譜的有效網址。如果無法提供有效網址，請明確說明無法提供，另外你也能依據使用者的想法推薦相關食譜詳細做法。請用繁體中文回答，並按照以下格式回覆：
//        
//        🥙       (這裡請務必提供食譜名稱，尤其是使用者問你有什麼相關食材料理推薦)
//        🥬【食材】（必須提供所有食材，並包含數量和單位，格式為：數量 單位 食材名稱）
//        • 2 個 蘋果
//        • 1 杯 牛奶
//        • ...
//        
//        🍳【烹飪步驟】（詳細描述每個步驟，不要忽略任何一句話，除非太多寫不下去，可以顯示....更多步驟）
//        1. 步驟一
//        2. 步驟二
//        3. 步驟三
//        ...
//        
//        🔗【食譜連結】
//        請提供一個與使用者提問的食譜的有效網址。
//        
//        👩🏻‍🍳【貼心提醒】
//        ...Bon appetit 🍽️
//        
//        """
//    )
//    
//    @State private var inputText = ""
//    @State private var messages: [Message] = []
//    @State private var showPhotoOptions = false
//    @State private var photoSource: PhotoSource?
//    @State private var image: UIImage?
//    @State private var showChangePhotoDialog = false
//    @State private var errorMessage: String?
//    
//    enum PhotoSource: Identifiable {
//        case photoLibrary
//        case camera
//        var id: Int { self.hashValue }
//    }
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // 漸層背景
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//              
//                Color.clear
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        IQKeyboardManager.shared.resignFirstResponder()
//                    }
//                
//                VStack {
//                    if let errorMessage = errorMessage {
//                        Text(errorMessage)
//                            .foregroundColor(.red)
//                            .padding()
//                    }
//                    
//                    Image("LogoFridgeChef")
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 300, height: 38)
//                        .padding(.top)
//                    
//                    ScrollView {
//                        VStack(alignment: .leading, spacing: 10) {
//                            ForEach(messages) { message in
//                                messageView(for: message)
//                            }
//                        }
//                    }
//                    
//                    if isWaitingForResponse {
//                        ProgressView()
//                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
//                            .scaleEffect(1.5)
//                            .padding()
//                            .background(Color.clear)
//                    }
//                    
//                    if let image = image {
//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 100)
//                            .cornerRadius(15)
//                            .shadow(radius: 3)
//                            .padding(.horizontal)
//                            .padding(.vertical, 5)
//                            .onTapGesture {
//                                self.showChangePhotoDialog = true
//                            }
//                            .confirmationDialog("想換張照片嗎？", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
//                                Button("換一張") {
//                                    showPhotoOptions = true
//                                }
//                                Button("移除照片", role: .destructive) {
//                                    self.image = nil
//                                }
//                                Button("取消", role: .cancel) {}
//                            }
//                    }
//                    HStack {
//                        Button(action: { showPhotoOptions = true }) {
//                            Image(systemName: "camera.fill")
//                                .resizable()
//                                .scaledToFit() // Ensure the image scales properly within the frame
//                                .frame(width: 40, height: 40)
//                                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                        }
//                        .padding(.leading, 10)
//                        .fixedSize() // Prevent the button from being compressed
//                        .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
//                            Button("相機") { photoSource = .camera }
//                            Button("相冊") { photoSource = .photoLibrary }
//                        }
//                        
//                        Spacer(minLength: 20) // Ensures space distribution
//                        
//                        PlaceholderTextEditor(text: $inputText, placeholder: "今天想來點 🥙🍍 ...")
//                            .frame(maxHeight: 100) // Consistent height with buttons
//                        
//                        Spacer(minLength: 20) // Ensures space distribution
//                        
//                        Button(action: sendMessage) {
//                            Image(systemName: "paperplane.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 35, height: 35)
//                                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                        }
//                        .padding(.trailing, 10)
//                        .fixedSize() // Prevent the button from being compressed
//                    }
//                    .padding(.horizontal)
//                }
//                .fullScreenCover(item: $photoSource) { source in
//                    ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
//                        .ignoresSafeArea()
//                }
//            }
//        }
//    }
//    
//    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
//        
//        guard let model = try? VNCoreMLModel(for: Food().model) else {
//            print("Failed to load model")
//            completion("未知食材")
//            return
//        }
//        
//        let request = VNCoreMLRequest(model: model) { request, error in
//            guard let results = request.results as? [VNClassificationObservation],
//                  let topResult = results.first else {
//                print("No results: \(error?.localizedDescription ?? "Unknown error")")
//                completion("未知食材")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                let label = topResult.identifier
//                let translatedLabel = TranslationDictionary.foodNames[label] ?? "未知食材"
//                completion(translatedLabel)
//            }
//        }
//        
//        guard let ciImage = CIImage(image: image) else {
//            print("Unable to create \(CIImage.self) from \(image).")
//            completion("未知食材")
//            return
//        }
//        
//        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Failed to perform classification.\n\(error.localizedDescription)")
//                completion("未知食材")
//            }
//        }
//    }
//    
//    func parseRecipe(from message: String) -> ParsedRecipe {
//        var title: String?
//        var ingredients: [ParsedIngredient] = []
//        var steps: [String] = []
//        var link: String?
//        var tips: String?
//        var unparsedContent: String? = ""
//        
//        let lines = message.components(separatedBy: "\n")
//        var currentSection: String?
//        
//        var isParsed = false
//        
//        func processIngredientsLine(_ line: String) {
//            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "")
//            if !trimmedLine.isEmpty {
//                let pattern = #"^(\d+\.?\d*)\s*([^\d\s]+)?\s+(.+)$"#
//                if let regex = try? NSRegularExpression(pattern: pattern),
//                   let match = regex.firstMatch(in: trimmedLine, options: [], range: NSRange(location: 0, length: trimmedLine.utf16.count)) {
//                    
//                    let quantityRange = Range(match.range(at: 1), in: trimmedLine)
//                    let unitRange = Range(match.range(at: 2), in: trimmedLine)
//                    let nameRange = Range(match.range(at: 3), in: trimmedLine)
//                    
//                    let quantity = quantityRange.map { String(trimmedLine[$0]) } ?? ""
//                    let unit = unitRange.map { String(trimmedLine[$0]) } ?? ""
//                    let name = nameRange.map { String(trimmedLine[$0]) } ?? trimmedLine
//                    
//                    ingredients.append(ParsedIngredient(name: name, quantity: quantity, unit: unit))
//                } else {
//                    // 如果无法解析，全部作为名称
//                    ingredients.append(ParsedIngredient(name: trimmedLine, quantity: "", unit: ""))
//                }
//            }
//        }
//        
//        func processStepsLine(_ line: String) {
//            var trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
//            if !trimmedLine.isEmpty {
//                trimmedLine = removeLeadingNumber(from: trimmedLine)
//                steps.append(trimmedLine)
//            }
//        }
//        
//        func processLinkLine(_ line: String) {
//            if let urlRange = line.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
//                link = String(line[urlRange])
//            } else {
//                // 如果无法提取链接，检查是否有提示无法提供链接的文本
//                if line.contains("無法提供") || line.contains("抱歉") {
//                    link = nil
//                } else {
//                    // 如果有其他文本，可能是一个 URL，但没有以 http 开头，尝试补全
//                    let potentialLink = line.trimmingCharacters(in: .whitespacesAndNewlines)
//                    if !potentialLink.isEmpty {
//                        link = "https://" + potentialLink
//                    } else {
//                        link = nil
//                    }
//                }
//            }
//        }
//        
//        func processTipsLine(_ line: String) {
//            tips = (tips ?? "") + line + "\n"
//        }
//        
//        // 主循环
//        for line in lines {
//            if line.contains("🥙") {
//                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//                cleanedLine = cleanedLine.replacingOccurrences(of: "食譜名稱：", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//                
//                
//                if let range = cleanedLine.range(of: #"(?<=\().*(?=\))"#, options: .regularExpression) {
//                   
//                    title = String(cleanedLine[range])
//                } else {
//                   
//                    title = cleanedLine
//                }
//                
//                isParsed = true
//                continue
//            }
//
//            if line.contains("【食材】") {
//                currentSection = "ingredients"
//                isParsed = true
//                continue
//            }
//            if line.contains("【烹飪步驟】") {
//                currentSection = "steps"
//                isParsed = true
//                continue
//            }
//            if line.contains("【食譜連結】") {
//                currentSection = "link"
//                isParsed = true
//                continue
//            }
//            if line.contains("【貼心提醒】") {
//                currentSection = "tips"
//                isParsed = true
//                continue
//            }
//            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                continue
//            }
//            
//            switch currentSection {
//            case "ingredients":
//                processIngredientsLine(line)
//            case "steps":
//                processStepsLine(line)
//            case "link":
//                processLinkLine(line)
//            case "tips":
//                processTipsLine(line)
//            default:
//                unparsedContent? += line + "\n"
//            }
//        }
//        
//        tips = tips?.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // 如果未成功解析，则将整个消息内容作为未解析内容
//        if !isParsed {
//            unparsedContent = message
//        }
//        
//        print("Parsed Recipe: \(ParsedRecipe(title: title, ingredients: ingredients, steps: steps, link: link, tips: tips))")
//        
//        return ParsedRecipe(title: title, ingredients: ingredients, steps: steps, link: link, tips: tips, unparsedContent: unparsedContent)
//    }
//    
//    func removeLeadingNumber(from string: String) -> String {
//        let pattern = #"^\s*\d+[\.\、]?\s*"#  // 匹配数字后跟 "."、"、" 或空格
//        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
//            let range = NSRange(string.startIndex..., in: string)
//            return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
//        } else {
//            return string
//        }
//    }
//    
//    private func messageView(for message: Message) -> some View {
//        let messageId = message.id
//        
//        return HStack {
//            if let recipe = parsedRecipes[messageId] {
//                // 已解析的訊息
//                if message.role == .user {
//                    Spacer()
//                    VStack(alignment: .trailing) {
//                        if let image = message.image {
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 150)
//                                .cornerRadius(10)
//                        }
//                        if let content = message.content {
//                            Text(content)
//                                .padding()
//                                .background(Color.customColor(named: "NavigationBarTitle"))
//                                .foregroundColor(.white)
//                                .bold()
//                                .cornerRadius(10)
//                        }
//                    }
//                } else {
//                    // 顯示已解析的食譜內容
//                    VStack(alignment: .leading, spacing: 10) {
//                        // 顯示食譜名稱
//                        if let title = recipe.title {
//                            Text(" \(title) 🥙")
//                                .font(.title3)
//                                .bold()
//                                .padding(.bottom, 5)
//                        }
//                        
//                        // 顯示食材列表
//                        if !recipe.ingredients.isEmpty {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("🥬【食材】")
//                                    .font(.headline)
//                                ForEach(recipe.ingredients, id: \.name) { ingredient in
//                                    IngredientRow(ingredient: ingredient, addAction: addIngredientToShoppingList)
//                                }
//                            }
//                            .padding()
//                            .background(Color.purple.opacity(0.1))
//                            .cornerRadius(10)
//                        }
//                        
//                        // 顯示烹飪步驟
//                        if !recipe.steps.isEmpty {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("🍳【烹飪步驟】")
//                                    .font(.headline)
//                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
//                                    HStack(alignment: .top) {
//                                        Text("\(index + 1).")
//                                            .bold()
//                                        Text(step)
//                                            .padding(.vertical, 2)
//                                    }
//                                }
//                            }
//                            .padding()
//                            .background(Color.orange.opacity(0.3))
//                            .cornerRadius(10)
//                        }
//                        
//                        // 顯示食譜連結
//                        if let link = recipe.link, let url = URL(string: link) {
//                            Link(destination: url) {
//                                HStack {
//                                    Text("🔗 查看完整食譜")
//                                        .font(.headline)
//                                        .foregroundColor(.blue)
//                                }
//                                .padding()
//                                .background(Color.blue.opacity(0.1))
//                                .cornerRadius(10)
//                            }
//                        } else {
//                            Text("抱歉，我目前無法提供該料理的食譜連結。如果您有任何其他食材或菜式需要幫忙，歡迎隨時告訴我！讓我來幫助您找到更多美味的食譜。👨🏻‍🌾")
//                                .padding()
//                                .background(Color.gray.opacity(0.1))
//                                .cornerRadius(10)
//                        }
//                        
//                        // 顯示貼心提醒
//                        if let tips = recipe.tips {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("👩🏻‍🍳【貼心提醒】")
//                                    .font(.headline)
//                                Text(tips)
//                            }
//                            .padding()
//                            .background(Color.blue.opacity(0.1))
//                            .cornerRadius(10)
//                        }
//                    }
//                    Spacer()
//                }
//            } else {
//                // 未解析的訊息
//                if message.role == .user {
//                    Spacer()
//                    VStack(alignment: .trailing) {
//                        if let image = message.image {
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 150)
//                                .cornerRadius(10)
//                        }
//                        if let content = message.content {
//                            Text(content)
//                                .padding()
//                                .background(Color.customColor(named: "NavigationBarTitle"))
//                                .foregroundColor(.white)
//                                .bold()
//                                .cornerRadius(10)
//                        }
//                    }
//                } else {
//                    VStack(alignment: .leading) {
//                        if let content = message.content {
//                            Text(content)
//                                .padding()
//                                .background(Color.white.opacity(0.8))
//                                .cornerRadius(10)
//                        }
//                    }
//                    Spacer()
//                }
//            }
//        }
//        .padding(.horizontal)
//    }
//
//    
//    func fetchRecipeLink(recipeName: String) async -> String? {
//        let service = RecipeSearchService()
//        return await withCheckedContinuation { continuation in
//            service.searchRecipes(query: recipeName, maxFat: nil) { result in
//                switch result {
//                case .success(let response):
//                    if let firstRecipe = response.results.first {
//                        // 获取食谱详情，包含 sourceUrl
//                        service.getRecipeInformation(recipeId: firstRecipe.id) { detailResult in
//                            switch detailResult {
//                            case .success(let details):
//                                continuation.resume(returning: details.sourceUrl)
//                            case .failure(let error):
//                                print("Error fetching recipe details: \(error)")
//                                continuation.resume(returning: nil)
//                            }
//                        }
//                    } else {
//                        print("No recipes found for \(recipeName)")
//                        continuation.resume(returning: nil)
//                    }
//                case .failure(let error):
//                    print("Error searching recipes: \(error)")
//                    continuation.resume(returning: nil)
//                }
//            }
//        }
//    }
//    
//    
//    func removeIngredientsSection(from message: String) -> String {
//        var lines = message.components(separatedBy: "\n")
//        var newLines: [String] = []
//        var isIngredientSection = false
//        
//        for line in lines {
//            if line.contains("【食材】") {
//                isIngredientSection = true
//                continue
//            } else if line.contains("【烹飪步驟】") || line.contains("🍳") {
//                isIngredientSection = false
//            }
//            
//            if !isIngredientSection {
//                newLines.append(line)
//            }
//        }
//        return newLines.joined(separator: "\n")
//    }
//    
//    func addIngredientToShoppingList(_ ingredient: ParsedIngredient) {
//        let newFoodItem = FoodItem(
//            name: ingredient.name,
//            quantity: Int(ingredient.quantity) ?? 1,
//            unit: ingredient.unit,
//            status: "To Buy",
//            daysRemaining: 2,
//            image: nil
//        )
//        foodItemStore.foodItems.append(newFoodItem)
//    }
//    
//    
//    func extractIngredients(from message: String) -> [String] {
//        var ingredients: [String] = []
//        let lines = message.components(separatedBy: "\n")
//        var isIngredientSection = false
//        
//        for line in lines {
//            if line.contains("【食材】") {
//                isIngredientSection = true
//                continue
//            } else if line.contains("【烹飪步驟】") || line.contains("🍳") {
//                break
//            }
//            
//            if isIngredientSection {
//                // 移除前面的符号和空格
//                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "")
//                if !trimmedLine.isEmpty {
//                    ingredients.append(trimmedLine)
//                }
//            }
//        }
//        return ingredients
//    }
//    
//    
//    func sendMessage() {
//        // 檢查輸入文本和圖片是否為空
//        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else { return }
//        
//        let messageText = inputText
//        let messageImage = image
//        
//        inputText = ""
//        image = nil
//        
//        if let messageImage = messageImage {
//            let imageMessage = Message(role: .user, content: nil, image: messageImage)
//            self.messages.append(imageMessage)
//        }
//        
//        if !messageText.isEmpty {
//            let userMessage = Message(role: .user, content: messageText, image: nil)
//            self.messages.append(userMessage)
//        }
//        
//        isWaitingForResponse = true
//        
//        Task {
//            do {
//                var finalMessageText = messageText
//                
//                if let messageImage = messageImage {
//                    // 進行食材識別
//                    recognizeFood(in: messageImage) { recognizedText in
//                        DispatchQueue.main.async {
//                            // 將識別結果添加到訊息文本
//                            if !finalMessageText.isEmpty {
//                                finalMessageText += "\n識別的食材：\(recognizedText)。\n請提供詳細的食譜和烹飪步驟。"
//                            } else {
//                                finalMessageText = "識別的食材：\(recognizedText)。\n請提供詳細的食譜和烹飪步驟。"
//                            }
//                            
//                            // 更新使用者訊息
//                            if !finalMessageText.isEmpty {
//                                let updatedUserMessage = Message(role: .user, content: finalMessageText, image: nil)
//                                self.messages.append(updatedUserMessage)
//                            }
//                            
//                            // 發送訊息給 API
//                            Task {
//                                do {
//                                    let responseText = try await api.sendMessage(finalMessageText)
//                                    let responseMessage = Message(role: .assistant, content: responseText, image: nil)
//                                    DispatchQueue.main.async {
//                                        self.messages.append(responseMessage)
//                                        self.errorMessage = nil
//                                        self.isWaitingForResponse = false
//                                    }
//                                    
//                                    // 解析食譜並獲取連結
//                                    if let responseContent = responseMessage.content {
//                                        var parsedRecipe = parseRecipe(from: responseContent)
//                                        if parsedRecipe.link == nil, let title = parsedRecipe.title {
//                                            if let link = await fetchRecipeLink(recipeName: title) {
//                                                parsedRecipe.link = link
//                                            }
//                                        }
//                                        DispatchQueue.main.async {
//                                            self.parsedRecipes[responseMessage.id] = parsedRecipe
//                                        }
//                                    }
//                                } catch {
//                                    print("發送訊息時出錯：\(error)")
//                                    DispatchQueue.main.async {
//                                        self.errorMessage = "發送訊息時出錯：\(error.localizedDescription)"
//                                        self.isWaitingForResponse = false
//                                    }
//                                }
//                            }
//                        }
//                    }
//                } else {
//                    // 沒有圖片，直接發送訊息
//                    if !finalMessageText.isEmpty {
//                        let responseText = try await api.sendMessage(finalMessageText)
//                        let responseMessage = Message(role: .assistant, content: responseText, image: nil)
//                        DispatchQueue.main.async {
//                            self.messages.append(responseMessage)
//                            self.errorMessage = nil
//                            self.isWaitingForResponse = false
//                        }
//                        
//                        // 解析食譜並獲取連結
//                        if let responseContent = responseMessage.content {
//                            var parsedRecipe = parseRecipe(from: responseContent)
//                            
////                            // 任何情況下都從 Spoonacular API 獲取連結
////                            if let title = parsedRecipe.title {
////                                if let link = await fetchRecipeLink(recipeName: title) {
////                                    parsedRecipe.link = link
////                                }
////                            }
//                            
////
////                            當助理的回覆沒有提供連結時（即 parsedRecipe.link == nil），程式會嘗試從 Spoonacular API 獲取連結。
//                            if parsedRecipe.link == nil, let title = parsedRecipe.title {
//                                if let link = await fetchRecipeLink(recipeName: title) {
//                                    parsedRecipe.link = link
//                                }
//                            }
//                            
//                            DispatchQueue.main.async {
//                                self.parsedRecipes[responseMessage.id] = parsedRecipe
//                            }
//                        }
//                    }
//                }
//            } catch {
//                print("發送訊息時出錯：\(error)")
//                DispatchQueue.main.async {
//                    self.errorMessage = "發送訊息時出錯：\(error.localizedDescription)"
//                    self.isWaitingForResponse = false
//                }
//            }
//        }
//    }
//
//    
//    func sendMessageToAPI(message: String) {
//        Task {
//            do {
//                let responseText = try await api.sendMessage(message)
//                DispatchQueue.main.async {
//                    self.messages.append(Message(role: .assistant, content: responseText, image: nil))
//                    self.isWaitingForResponse = false
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "發送訊息出錯：\(error.localizedDescription)"
//                    self.isWaitingForResponse = false
//                }
//            }
//        }
//    }
//}
//
//struct IngredientRow: View {
//    var ingredient: ParsedIngredient
//    var addAction: (ParsedIngredient) -> Void
//    
//    @State private var showAlert = false
//    
//    var body: some View {
//        Button(action: {
//            addAction(ingredient)
//            showAlert = true
//        }) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(ingredient.name)
//                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                        .bold()
//                        .lineLimit(nil)  // 允许无限行，自动换行
//                        .fixedSize(horizontal: false, vertical: true)  // 允许 Text 根据内容调整大小
//                    if !ingredient.quantity.isEmpty {
//                        Text("數量：\(ingredient.quantity) \(ingredient.unit)")
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                    }
//                }
//                Spacer()
//                Image(systemName: "cart.badge.plus.fill")
//                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//            }
//            .padding(.vertical, 5)
//        }
//        .buttonStyle(PlainButtonStyle())
//        .alert(isPresented: $showAlert) {
//            Alert(
//                title: Text("已加入購物清單"),
//                message: Text("\(ingredient.name) 已加入您的購物清單。"),
//                dismissButton: .default(Text("好的"))
//            )
//        }
//    }
//}
//
//extension Color {
//    static func customColor(named name: String) -> Color {
//        return Color(UIColor(named: name) ?? .systemRed)
//    }
//}
//
//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView()
//    }
//}
//
