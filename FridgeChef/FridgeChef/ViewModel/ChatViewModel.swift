//
//  ChatViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import Firebase
import SDWebImageSwiftUI
import Vision
import NaturalLanguage
import IQKeyboardManagerSwift

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var image: UIImage?
    @Published var isWaitingForResponse = false
    @Published var errorMessage: String?
    @Published var showAlert = false
    @Published var isSearchVisible = false
    @Published var searchText = ""
    @Published var showPhotoOptions = false
    @Published var showChangePhotoDialog = false
    @Published var photoSource: PhotoSource?
    @Published var isButtonDisabled = false
    @Published var activeAlert: ActiveAlert?
    
    var showAlertClosure: ((ActiveAlert) -> Void)?
    var onAddIngredientToCart: ((ParsedIngredient) -> Void)?
    var pendingIngredientToAdd: ParsedIngredient?
    var accumulationCompletion: ((Bool) -> Void)?
    var alertTitle = ""
    var alertMessage = ""
    
    // MARK: - Private Properties
    
    private let firestoreService: FirestoreService
    private let apiService: APIService
    private var listener: ListenerRegistration?
    private var api: ChatGPTAPI?
    private var chatViewOpenedAt = Date()
    private var foodItemStore: FoodItemStore
    
    private let englishSystemPrompt = """
    You are a professional chef assistant capable of providing detailed recipes and cooking steps based on the ingredients, images, and descriptions provided by the user. Each reply must include the recipe name and a complete list of 【Ingredients】, along with a valid URL for the specified recipe. If a valid URL cannot be provided, please explicitly state so.
    
    🥙 Recipe Name: [Recipe Name]
    
    🥬【Ingredients】 (All ingredients must be provided, including quantities and units, formatted as: Quantity Unit Ingredient Name)
    • [Quantity] [Unit] [Ingredient]
    • ...
    
    🍳【Cooking Steps】 (Please provide fully detailed description of each step, starting with a number and a period)
    1. [Step One]
    2. [Step Two]
    3. ...
    
    🔗【Recipe Link】
    (Please provide a valid URL related to the recipe the user asked for.)
    
    👩🏻‍🍳【Friendly Reminder】
    (Here you can provide a friendly reminder or answer the user's questions.)
    
    Bon appetit 🍽️
    
    **Notes:**
    - Respond in the user's language based on their input.
    - Do not specify language in the system prompt.
    - Do not add extra titles, bold text, colons, or other symbols in the steps.
    - Each step should be a complete sentence, directly describing the action.
    - Additionally, you can recommend related recipes and detailed cooking methods based on the user's ideas.
    - Strictly follow the above format without adding any extra content or changing the format.
    """
    
    private let chineseSystemPrompt = """
    你是一位專業的廚師助手，能夠根據使用者提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。每次回覆必須包括食譜名稱和完整的【食材】列表，以及該食譜的有效連結。如果無法提供有效連結，請明確說明。
    
    🥙 食譜名稱：[菜名]
    
    🥬【食材】（請提供所有食材，包括數量和單位，格式為：數量 單位 食材名稱）
    • [數量] [單位] [食材]
    • ...
    
    🍳【烹飪步驟】（請提供每一步的詳細描述，以數字和句號開頭）
    1. [步驟一]
    2. [步驟二]
    3. ...
    
    🔗【食譜連結】
    （請提供與使用者要求的食譜相關的有效網址。）
    
    👩🏻‍🍳【友情提示】
    （在這裡你可以提供友情提示或回答使用者的問題。）
    
    Bon appetit 🍽️
    
    **注意事項：**
    - 根據使用者的輸入語言進行回覆。
    - 不要在系統提示中指定語言。
    - 不要在步驟中添加額外的標題、粗體、冒號或其他符號。
    - 每個步驟應為完整的句子，直接描述操作。
    - 此外，你可以根據使用者的想法推薦相關的食譜和詳細的烹飪方法。
    - 嚴格遵守以上格式，不要添加任何額外內容或更改格式。
    """
    
    // MARK: - Initialization
    
    init(foodItemStore: FoodItemStore, firestoreService: FirestoreService = FirestoreService(), apiService: APIService = APIService()) {
        self.foodItemStore = foodItemStore
        self.firestoreService = firestoreService
        self.apiService = apiService
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Enums
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }
    
    // MARK: - Helpers
    
    func isIngredientInCart(_ ingredient: ParsedIngredient) -> Bool {
        return foodItemStore.foodItems.contains { $0.name.lowercased() == ingredient.name.lowercased() }
    }
    
    func addIngredientToCart(_ ingredient: ParsedIngredient, foodItemStore: FoodItemStore) {
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.showAlertClosure?(.error(ErrorMessage(message: "No user is logged in.")))
            }
            return
        }
        
        if foodItemStore.foodItems.firstIndex(where: { $0.name.lowercased() == ingredient.name.lowercased() }) != nil {
            DispatchQueue.main.async {
                self.pendingIngredientToAdd = ingredient
                self.showAlertClosure?(.accumulation(ingredient))
            }
        } else {
            let newFoodItem = FoodItem(
                id: UUID().uuidString,
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                status: .toBuy,
                expirationDate: ingredient.expirationDate,
                imageURL: nil
            )
            
            DispatchQueue.main.async {
                foodItemStore.foodItems.append(newFoodItem)
                self.showAlertClosure?(.ingredient("\(ingredient.name) added to your Grocery List 🛒"))
            }
            
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
                if case let .failure(error) = result {
                    print("Failed to add food item to Firestore: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func onAppear() {
        chatViewOpenedAt = Date()
        if listener == nil {
            fetchMessages()
        }
    }
    
    func onDisappear() {
        listener?.remove()
        listener = nil
    }
    
    func fetchMessages() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        listener = firestoreService.listenForMessages(forUser: currentUser.uid, after: chatViewOpenedAt) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let fetchedMessages):
                    let newMessages = fetchedMessages.filter { fetchedMessage in
                        fetchedMessage.timestamp > self.chatViewOpenedAt &&
                        !self.messages.contains(where: { $0.id == fetchedMessage.id })
                    }
                    
                    let parsedNewMessages = newMessages.map { message in
                        var mutableMessage = message
                        if message.role == .assistant, let content = message.content {
                            mutableMessage.parsedRecipe = self.parseRecipe(from: content)
                            print("Parsed recipe for message ID \(message.id ?? "unknown"): \(mutableMessage.parsedRecipe?.title ?? "No Title")")
                        }
                        return mutableMessage
                    }
                    
                    self.messages.append(contentsOf: parsedNewMessages)
                    print("Fetched and updated messages: \(self.messages.count) messages")
                case .failure(let error):
                    print("Error fetching messages: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func sendMessage() {
        
        let messageText = inputText
        let messageImage = image
        inputText = ""
        image = nil
        
        isWaitingForResponse = true
        
        if let apiKey = KeychainManager.shared.getApiKey(forKey: "OpenAIAPI_Key"), !apiKey.isEmpty {
            let languageCode = detectLanguage(for: messageText)
            let systemPrompt = getSystemPrompt(for: languageCode)
            self.api = ChatGPTAPI(apiKey: apiKey, systemPrompt: systemPrompt)
        } else {
            print("API Key is missing!")
            self.alertTitle = "Missing API Key"
            self.alertMessage = "Please provide a valid API Key to use this feature."
            self.showAlert = true
            return
        }
        
        if let messageImage = messageImage {
            
            firestoreService.uploadImage(messageImage, path: "chat_images/\(UUID().uuidString).jpg") { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let imageURL):
                    self.recognizeFood(in: messageImage) { label in
                        let translatedLabel = TranslationDictionary.foodNames[label.lowercased()] ?? label
                        print("Original label: \(label), Translated label: \(translatedLabel)")
                        
                        guard !translatedLabel.isEmpty else {
                            self.errorMessage = "Could not identify any ingredients. Please try again."
                            self.triggerAlert(title: "Error", message: "Could not identify any ingredients. Please try again.")
                            self.isWaitingForResponse = false
                            return
                        }
                        
                        let finalMessageText = "Identified ingredient: \(translatedLabel).\nPlease provide detailed recipes and cooking steps."
                        
                        let userMessage = Message(
                            id: nil,
                            role: .user,
                            content: finalMessageText,
                            imageURL: imageURL,
                            timestamp: Date(),
                            parsedRecipe: nil
                        )
                        
                        self.saveMessageToFirestore(userMessage)
                        self.checkCachedResponseAndRespond(message: finalMessageText)
                    }
                case .failure(let error):
                    self.triggerAlert(title: "Error", message: "Failed to upload image: \(error.localizedDescription)")
                    self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    print(self.errorMessage!)
                    self.isWaitingForResponse = false
                }
            }
        } else {
            let userMessage = Message(
                id: nil,
                role: .user,
                content: messageText,
                imageURL: nil,
                timestamp: Date(),
                parsedRecipe: nil
            )
            saveMessageToFirestore(userMessage)
            checkCachedResponseAndRespond(message: messageText)
        }
    }
    
    @MainActor
    func addIngredientToShoppingList(_ ingredient: ParsedIngredient) async -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            self.activeAlert = .error(ErrorMessage(message: "No user is logged in."))
            return false
        }
        
        let newFoodItem = FoodItem(
            id: UUID().uuidString,
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            status: .toBuy,
            expirationDate: ingredient.expirationDate,
            imageURL: nil
        )
        
        if let _ = foodItemStore.foodItems.firstIndex(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
            self.activeAlert = .accumulation(ingredient)
            return false
        } else {
            foodItemStore.foodItems.append(newFoodItem)
            self.activeAlert = .ingredient("\(ingredient.name) added to your Grocery List 🛒")
            
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
                if case let .failure(error) = result {
                    print("Failed to add food item to Firestore: \(error.localizedDescription)")
                }
            }
            
            return true
        }
    }
    
    // MARK: - Handle Accumulation Choice
    
    func handleAccumulationChoice(for ingredient: ParsedIngredient, accumulate: Bool, foodItemStore: FoodItemStore) {
        guard let existingIndex = foodItemStore.foodItems.firstIndex(where: { $0.name.lowercased() == ingredient.name.lowercased() }) else {
            return
        }
        
        if accumulate {
            let newQuantity = foodItemStore.foodItems[existingIndex].quantity + ingredient.quantity
            
            DispatchQueue.main.async {
                foodItemStore.foodItems[existingIndex].quantity = newQuantity
            }
            
            if let userId = Auth.auth().currentUser?.uid {
                let updatedFields: [String: Any] = ["quantity": newQuantity]
                firestoreService.updateFoodItem(forUser: userId, foodItemId: foodItemStore.foodItems[existingIndex].id, updatedFields: updatedFields) { result in
                    if case let .failure(error) = result {
                        print("Failed to update food item quantity in Firestore: \(error.localizedDescription)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.showAlertClosure?(.ingredient("Updated quantity of \(ingredient.name) to \(newQuantity) \(ingredient.unit)."))
            }
        } else {
            DispatchQueue.main.async {
                self.showAlertClosure?(.regular(
                    title: "No Changes Made",
                    message: "\(ingredient.name) remains at \(foodItemStore.foodItems[existingIndex].quantity) \(ingredient.unit)."
                ))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func triggerAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    private func saveMessageToFirestore(_ message: Message) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        firestoreService.saveMessage(message, forUser: currentUser.uid) { result in
            switch result {
            case .success:
                print("Message successfully saved to Firestore.")
            case .failure(let error):
                print("Failed to save message to Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkCachedResponseAndRespond(message: String) {
        let standardizedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        firestoreService.getCachedResponse(message: standardizedMessage) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let cachedResponse):
                if let cachedResponse = cachedResponse {
                    print("Use Cache Response: \(cachedResponse.response)")
                    let assistantMessage = Message(
                        id: nil,
                        role: .assistant,
                        content: cachedResponse.response,
                        imageURL: nil,
                        timestamp: Date(),
                        parsedRecipe: self.parseRecipe(from: cachedResponse.response)
                    )
                    
                    self.saveMessageToFirestore(assistantMessage)
                    self.isWaitingForResponse = false
                } else {
                    print("No Cache, calling API")
                    self.sendMessageToAssistant(message: standardizedMessage)
                }
            case .failure(let error):
                print("Cache Response failure: \(error)")
                self.sendMessageToAssistant(message: standardizedMessage)
            }
        }
    }
    
    private func sendMessageToAssistant(message: String) {
        guard let api = api else {
            self.triggerAlert(title: "Missing API Key", message: "Please provide a valid API Key.")
            return
        }
        
        guard !message.isEmpty else {
            self.isWaitingForResponse = false
            return
        }
        
        let messageToSend = message
        
        Task {
            do {
                print("📤 Calling API and sending messages: \(messageToSend)")
                let responseText = try await api.sendMessage(messageToSend)
                print("📥 Taking API response: \(responseText)")
                
                let parsedRecipe = parseRecipe(from: responseText)
                
                guard Auth.auth().currentUser != nil else {
                    print("🔒 No user log in.")
                    self.isWaitingForResponse = false
                    return
                }
                
                firestoreService.saveCachedResponse(message: messageToSend, response: responseText) { result in
                    switch result {
                    case .success():
                        print("✅ Saving Cache Response.")
                    case .failure(let error):
                        print("❌ Cannot save Cache Response: \(error)")
                    }
                }
                
                let responseMessage = Message(
                    id: nil,
                    role: .assistant,
                    content: responseText,
                    imageURL: nil,
                    timestamp: Date(),
                    parsedRecipe: parsedRecipe
                )
                
                await MainActor.run {
                    self.isWaitingForResponse = false
                    self.saveMessageToFirestore(responseMessage)
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Sending message error: \(error.localizedDescription)"
                    self.isWaitingForResponse = false
                }
                print("❌ Sending message error: \(error)")
            }
        }
    }
    
    private func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        
        do {
            let model = try VNCoreMLModel(for: Food(configuration: configuration).model)
            
            // Create Vision request
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    print("No results: \(error?.localizedDescription ?? "Unknown error")")
                    completion("Unknown Food")
                    return
                }
                let label = topResult.identifier
                DispatchQueue.main.async {
                    completion(label)
                }
            }
            
            guard let ciImage = CIImage(image: image) else {
                print("Unable to create \(CIImage.self) from \(image).")
                completion("Unknown Food")
                return
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform classification.\n\(error.localizedDescription)")
                    completion("Unknown Food")
                }
            }
            
        } catch {
            print("Failed to load model with configuration: \(error.localizedDescription)")
            completion("Unknown Food")
        }
    }
    
    // MARK: - Parsing Functions
    
    private func parseRecipe(from message: String) -> ParsedRecipe {
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
            if !trimmedLine.isEmpty && trimmedLine != "..." {
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
                    
                    let expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    
                    let ingredient = ParsedIngredient(name: name, quantity: quantityDouble, unit: unit, expirationDate: expirationDate)
                    ingredients.append(ingredient)
                    
                    print("Parsed Ingredient: \(ingredient)")
                } else {
                    let ingredient = ParsedIngredient(name: trimmedLine, quantity: 1.0, unit: "unit", expirationDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                    ingredients.append(ingredient)
                    
                    print("Parsed Ingredient with Defaults: \(ingredient)")
                }
            }
        }
        
        func processStepsLine(_ line: String) {
            var trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                trimmedLine = removeLeadingNumber(from: trimmedLine)
                steps.append(trimmedLine)
                
                print("Parsed Step: \(trimmedLine)")
            }
        }
        
        func processLinkLine(_ line: String) {
            if let urlRange = line.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
                link = String(line[urlRange])
                print("Parsed Link: \(link!)")
            } else if let urlRange = line.range(of: #"www\.[^\s]+"#, options: .regularExpression) {
                link = "https://" + String(line[urlRange])
                print("Auto-corrected and Parsed Link: \(link!)")
            } else {
                print("Failed to parse a valid link.")
                link = nil
            }
        }
        
        func processTipsLine(_ line: String) {
            tips = (tips ?? "") + line + "\n"
            print("Parsed Tip: \(line)")
        }
        
        for line in lines {
            if line.contains("🥙") && (line.contains("Recipe Name") || line.contains("食譜名稱")) {
                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cleanedLine = cleanedLine.replacingOccurrences(of: "Recipe Name:", with: "").replacingOccurrences(of: "食譜名稱：", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                title = cleanedLine
                print("Parsed Title: \(title!)")
                isParsed = true
                continue
            }
            
            if line.contains("【Ingredients】") || line.contains("【食材】") {
                currentSection = "ingredients"
                isParsed = true
                continue
            }
            if line.contains("【Cooking Steps】") || line.contains("【烹飪步驟】") {
                currentSection = "steps"
                isParsed = true
                continue
            }
            if line.contains("【Recipe Link】") || line.contains("【食譜連結】") {
                currentSection = "link"
                isParsed = true
                continue
            }
            if line.contains("【Friendly Reminder】") || line.contains("【友情提示】") {
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
        
        if !isParsed {
            unparsedContent = message
            print("Parsed Recipe with Unparsed Content: \(String(describing: unparsedContent))")
        }
        
        let parsedRecipe = ParsedRecipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            link: link,
            tips: tips,
            unparsedContent: unparsedContent
        )
        
        print("Final Parsed Recipe: \(parsedRecipe)")
        
        return parsedRecipe
    }
    
    private func removeLeadingNumber(from string: String) -> String {
        let pattern = #"^\s*\d+[\.\、]?\s*"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(string.startIndex..., in: string)
            return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        } else {
            return string
        }
    }
    
    // MARK: - Additional Functions
    
    func extractIngredients(from message: String) -> [String] {
        var ingredients: [String] = []
        let lines = message.components(separatedBy: "\n")
        var isIngredientSection = false
        
        for line in lines {
            if line.contains("【Ingredients】") {
                isIngredientSection = true
                continue
            } else if line.contains("【Cooking Steps】") || line.contains("🍳") {
                break
            }
            
            if isIngredientSection {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "• ", with: "")
                if !trimmedLine.isEmpty {
                    ingredients.append(trimmedLine)
                }
            }
        }
        return ingredients
    }
    
    func fetchRecipeLink(recipeName: String) async -> String? {
        let service = RecipeSearchService()
        return await withCheckedContinuation { continuation in
            service.searchRecipes(query: recipeName, maxFat: nil) { result in
                switch result {
                case .success(let response):
                    if let firstRecipe = response.results.first {
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
        let lines = message.components(separatedBy: "\n")
        var newLines: [String] = []
        var isIngredientSection = false
        
        for line in lines {
            if line.contains("【Ingredients】") {
                isIngredientSection = true
                continue
            } else if line.contains("【Cooking Steps】") || line.contains("🍳") {
                isIngredientSection = false
            }
            
            if !isIngredientSection {
                newLines.append(line)
            }
        }
        return newLines.joined(separator: "\n")
    }
    
    // MARK: - Computed Properties
    
    var filteredMessages: [Message] {
        if searchText.isEmpty {
            return messages
        } else {
            return messages.filter { message in
                if let content = message.content {
                    return content.lowercased().contains(searchText.lowercased())
                } else {
                    return false
                }
            }
        }
    }
    
    // MARK: - Language Detection and System Prompt
    
    private func detectLanguage(for text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        if let language = recognizer.dominantLanguage {
            return language.rawValue
        }
        return "en"
    }
    
    private func getSystemPrompt(for languageCode: String) -> String {
        switch languageCode {
        case "zh-Hant", "zh-Hans":
            return chineseSystemPrompt
        case "en":
            return englishSystemPrompt
         
        default:
            return englishSystemPrompt
        }
    }
}
