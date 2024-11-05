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
    
    // MARK: - Initialization
    
    init(foodItemStore: FoodItemStore, firestoreService: FirestoreService = FirestoreService(), apiService: APIService = APIService()) {
        self.foodItemStore = foodItemStore
        self.firestoreService = firestoreService
        self.apiService = apiService
        
        if let apiKey = KeychainManager.shared.getApiKey(forKey: "OpenAIAPI_Key"), !apiKey.isEmpty {
            self.api = ChatGPTAPI(apiKey: apiKey, systemPrompt: """
            You are a professional chef assistant capable of providing detailed recipes and cooking steps based on the ingredients, images, and descriptions provided by the user. Each reply must include the recipe name and a complete list of 【Ingredients】, along with a valid URL for the specified recipe. If a valid URL cannot be provided, please explicitly state so.
            
            🥙 Recipe Name: [English Name]
            
            🥬【Ingredients】 (All ingredients must be provided, including quantities and units, formatted as: Quantity Unit Ingredient Name)
            • 2 apples
            • 1 cup milk
            • ...
            
            🍳【Cooking Steps】 (Please provide fully detailed description of each step, starting with a number and a period, direct description without adding extra titles, bold text, colons, or other symbols)
            1. Step one
            2. Step two
            3. Step three
            4. ...
            
            🔗【Recipe Link】
            (Please provide a valid URL related to the recipe the user asked for.)
            
            👩🏻‍🍳【Friendly Reminder】
            (Here you can provide a friendly reminder or answer the user's questions.)
            
            Bon appetit 🍽️
            
            **Notes:**
            - Respond in the user's language based on their input. Do not specify language in the system prompt.
            - Do not add extra titles, bold text, colons, or other symbols in the steps.
            - Each step should be a complete sentence, directly describing the action.
            - Additionally, you can recommend related recipes and detailed cooking methods based on the user's ideas.
            - Strictly follow the above format without adding any extra content or changing the format.
            """
            )
        } else {
            print("API Key is missing!")
            self.alertTitle = "Missing API Key"
            self.alertMessage = "Please provide a valid API Key to use this feature."
            self.showAlert = true
        }
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
                daysRemaining: Calendar.current.dateComponents([.day], from: Date(), to: ingredient.expirationDate).day ?? 0,
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
        fetchMessages()
    }
    
    func onDisappear() {
        listener?.remove()
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
        guard api != nil else {
            self.alertTitle = "Missing API Key"
            self.alertMessage = "Please provide a valid API Key to use this feature."
            self.showAlert = true
            return
        }
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else {
            print("No text or image to send")
            return
        }
        
        let messageText = inputText
        let messageImage = image
        inputText = ""
        image = nil
        
        isWaitingForResponse = true
        
        let timestamp = Date()
        
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
                            timestamp: timestamp,
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
                timestamp: timestamp,
                parsedRecipe: nil
            )
            saveMessageToFirestore(userMessage)
            checkCachedResponseAndRespond(message: messageText)
        }
    }
    
    func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.activeAlert = .error(ErrorMessage(message: "No user is logged in."))
            }
            return false
        }
        
        let newFoodItem = FoodItem(
            id: UUID().uuidString,
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            status: .toBuy,
            daysRemaining: Calendar.current.dateComponents([.day], from: Date(), to: ingredient.expirationDate).day ?? 0,
            expirationDate: ingredient.expirationDate,
            imageURL: nil
        )
        
        if let _ = foodItemStore.foodItems.firstIndex(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
            DispatchQueue.main.async {
                self.activeAlert = .accumulation(ingredient)
            }
            return false
        } else {
            DispatchQueue.main.async {
                self.foodItemStore.foodItems.append(newFoodItem)
                self.activeAlert = .ingredient("\(ingredient.name) added to your Grocery List 🛒")
            }
            
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
                switch result {
                case .success:
                    print("Food item successfully added to Firestore.")
                case .failure(let error):
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
                    self.sendMessageToAssistant(standardizedMessage)
                }
            case .failure(let error):
                print("Cache Response failure: \(error)")
                self.sendMessageToAssistant(standardizedMessage)
            }
        }
    }
    
    private func sendMessageToAssistant(_ messageText: String) {
        guard let api = api else {
            self.triggerAlert(title: "Missing API Key", message: "Please provide a valid API Key.")
            return
        }
        
        guard !messageText.isEmpty else {
            self.isWaitingForResponse = false
            return
        }
        
        let messageToSend = messageText
        
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
                
                firestoreService.saveCachedResponse(message: messageText, response: responseText) { result in
                    switch result {
                    case .success():
                        print("✅ Saving Cache Response.")
                    case .failure(let error):
                        print("❌ Cannot saving Cache Response: \(error)")
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
                
                self.saveMessageToFirestore(responseMessage)
                self.errorMessage = nil
                self.isWaitingForResponse = false
                
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
                DispatchQueue.main.async {
                    self.errorMessage = "Sending message error: \(error.localizedDescription)"
                    self.isWaitingForResponse = false
                }
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
                    
                    // Set a default expirationDate, e.g., 3 days later
                    let expirationDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
                    
                    let ingredient = ParsedIngredient(name: name, quantity: quantityDouble, unit: unit, expirationDate: expirationDate)
                    ingredients.append(ingredient)
                    
                    print("Parsed Ingredient: \(ingredient)")
                } else {
                    let ingredient = ParsedIngredient(name: trimmedLine, quantity: 1.0, unit: "unit", expirationDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date())
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
            if line.contains("🥙") && line.contains("Recipe Name") {
                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cleanedLine = cleanedLine.replacingOccurrences(of: "Recipe Name:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                title = cleanedLine
                print("Parsed Title: \(title!)")
                isParsed = true
                continue
            }
            
            if line.contains("【Ingredients】") {
                currentSection = "ingredients"
                isParsed = true
                continue
            }
            if line.contains("【Cooking Steps】") {
                currentSection = "steps"
                isParsed = true
                continue
            }
            if line.contains("【Recipe Link】") {
                currentSection = "link"
                isParsed = true
                continue
            }
            if line.contains("【Friendly Reminder】") {
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
}

