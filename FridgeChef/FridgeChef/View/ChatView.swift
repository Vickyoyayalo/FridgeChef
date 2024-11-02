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
import NaturalLanguage
import IQKeyboardManagerSwift
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let role: ChatGPTRole
    let content: String?
    var imageURL: String?
    let timestamp: Date
    var parsedRecipe: ParsedRecipe?
    
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case imageURL
        case timestamp
        case parsedRecipe
    }
}

enum ChatGPTRole: String, Codable {
    case system
    case user
    case assistant
}

struct CachedResponse: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let message: String
    let response: String
    let timestamp: Date
}

struct PlaceholderTextEditor: View {
    @Binding var text: String
    var placeholder: String
    
    @State private var dynamicHeight: CGFloat = 44
    var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .onChange(of: text) { _ in
                    calculateHeight()
                }
            
            // 顯示 placeholder，當 text 為空時才顯示
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            calculateHeight() // 確保初始高度計算
        }
    }
    
    private func calculateHeight() {
        let maxSize = CGSize(width: UIScreen.main.bounds.width - 32, height: .infinity)
        let size = CGSize(width: maxSize.width, height: CGFloat.greatestFiniteMagnitude)
        
        let text = self.text.isEmpty ? " " : self.text
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17)]
        let rect = NSString(string: text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        DispatchQueue.main.async {
            self.dynamicHeight = rect.height + 24
        }
    }
}

struct ChatView: View {
    let firestoreService = FirestoreService()
    private let apiService = APIService()
    @State private var chatViewOpenedAt = Date()
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var searchText = ""
    @State private var inputText = ""
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var photoSource: PhotoSource?
    @State private var parsedRecipes: [String: ParsedRecipe] = [:]
    @State private var messages: [Message] = []
    @State private var image: UIImage?
    @State private var showAlert = false
    @State private var showPhotoOptions = false
    @State private var showChangePhotoDialog = false
    @State private var errorMessage: String? = nil
    @State private var isButtonDisabled = false
    @State private var moveRight = true
    @State private var isFetchingLink: Bool = false
    @State private var isWaitingForResponse = false
    @State private var isSearchVisible = false
    @State private var selectedMessageID: String? = nil
    @State private var listener: ListenerRegistration?
    @State private var api: ChatGPTAPI?
    
    init() {
        let apiKey = KeychainManager.shared.getApiKey(forKey: "OpenAIAPI_Key")
            print("Retrieved API Key from Keychain: \(apiKey ?? "nil")")
        if let apiKey = KeychainManager.shared.getApiKey(forKey: "OpenAIAPI_Key"), !apiKey.isEmpty {
            _api = State(initialValue: ChatGPTAPI(
                apiKey: apiKey,
                systemPrompt: """
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
                
            ))
        } else {
            print("API Key is missing!")
        }
    }
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }
    
    var body: some View {
        NavigationView {
            if Auth.auth().currentUser != nil {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                    GeometryReader { geometry in
                        VStack {
                            if messages.isEmpty {
                                VStack {
                                    Image("Chatmonster")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 300, height: 300)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.clear)
                            }
                        }
                        .onTapGesture {
                            IQKeyboardManager.shared.resignFirstResponder()
                        }
                        
                        VStack {
                            ZStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            isSearchVisible.toggle()
                                        }
                                    }) {
                                        Image(systemName: isSearchVisible ? "xmark.circle.fill" : "magnifyingglass")
                                            .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                            .imageScale(.medium)
                                            .padding()
                                    }
                                }
                                
                                Image("FridgeChefLogo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 38)
                                    .padding(.top)
                            }

                            if isSearchVisible {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.orange)
                                        .padding(.leading, 8)

                                    TextField("Search messages...", text: $searchText, onCommit: {
                                        performSearch()
                                    })
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.vertical, 8)
                                    .padding(.trailing, 8)

                                    if !searchText.isEmpty {
                                        Button(action: {
                                            self.searchText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.orange)
                                                .padding(.trailing, 8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).opacity(0.3))
                                .padding(.horizontal)
                                .transition(.move(edge: .trailing))
                            }

                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(filteredMessages) { message in
                                            messageView(for: message)
                                                .id(message.id)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .onChange(of: messages.count) { _ in
                                        if let lastMessage = messages.last, let id = lastMessage.id {
                                            DispatchQueue.main.async {
                                                withAnimation {
                                                    proxy.scrollTo(id, anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                }
                                .scrollIndicators(.hidden)
                            }
                            
                            if isWaitingForResponse {
                                MonsterAnimationView()
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
                                    .confirmationDialog("Wanna Change?", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
                                        Button("Change") {
                                            showPhotoOptions = true
                                        }
                                        Button("Remove", role: .destructive) {
                                            self.image = nil
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    }
                            }
                            
                            HStack {
                                Button(action: { showPhotoOptions = true }) {
                                    Image(systemName: "camera.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                }
                                .padding(.leading, 15)
                                .fixedSize()
                                .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                                    Button("Camera") { photoSource = .camera }
                                    Button("Photo Library") { photoSource = .photoLibrary }
                                }
                                
                                Spacer(minLength: 20)
                                
                                PlaceholderTextEditor(text: $inputText, placeholder: "Want ideas? 🥙 ...")
                                    .frame(minHeight: 40, maxHeight: 60)
                                
                                Spacer(minLength: 20)
                                
                                Button(action: sendMessage) {
                                    Image(systemName: "paperplane.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                }
                                .padding(.trailing, 15)
                                .fixedSize()
                            }
                            .padding(.bottom, 8)
                        }
                        
                    }
                    .onAppear {
                        chatViewOpenedAt = Date()
                        fetchMessages()
                    }
                    .onDisappear {
                        listener?.remove()
                    }
                }
            } else {
                VStack {
                    Text("Please login to continue chats!")
                        .padding()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(item: $photoSource) { source in
            ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                .ignoresSafeArea()
        }
        .onAppear {
            if api == nil {
                if let apiKey = KeychainManager.shared.getApiKey(forKey: "OpenAIAPI_Key"), !apiKey.isEmpty {
                    api = ChatGPTAPI(apiKey: apiKey, systemPrompt: "...")
                } else {
                    alertTitle = "Missing API Key"
                    alertMessage = "Please provide a valid API Key to use this feature."
                    showAlert = true
                }
            }
        }
    }
    
    func triggerAlert(title: String, message: String) {
        self.alertTitle = title
        self.errorMessage = message
        self.showAlert = true
    }
    
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

    func performSearch() {
        if let matchedMessage = messages.first(where: { $0.content?.lowercased().contains(searchText.lowercased()) ?? false }) {
            selectedMessageID = matchedMessage.id
        }
        searchText = ""
    }

    // MARK: - Fetch Messages
    func fetchMessages() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        listener = firestoreService.listenForMessages(forUser: currentUser.uid, after: chatViewOpenedAt) { result in
            switch result {
            case .success(let fetchedMessages):
                DispatchQueue.main.async {
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
                }
            case .failure(let error):
                print("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Save Message to Firestore
    func saveMessageToFirestore(_ message: Message) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }

        firestoreService.saveMessage(message, forUser: currentUser.uid) { result in
            switch result {
            case .success():
                print("Message successfully saved to Firestore.")
            case .failure(let error):
                print("Failed to save message to Firestore: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Send Message
    func sendMessage() {
        
        guard let api = api else {
            alertTitle = "Missing API Key"
            alertMessage = "Please provide a valid API Key to use this feature."
            showAlert = true
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
    
            firestoreService.uploadImage(messageImage, path: "chat_images/\(UUID().uuidString).jpg") { result in
                switch result {
                case .success(let imageURL):
                    recognizeFood(in: messageImage) { translatedLabel in
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
    
    func checkCachedResponseAndRespond(message: String) {
        let standardizedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        firestoreService.getCachedResponse(message: standardizedMessage) { result in
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

    // MARK: - Send Message to Assistant
    func sendMessageToAssistant(_ messageText: String) {
        guard let api = api else {
            alertTitle = "Missing API Key"
            alertMessage = "Please provide a valid API Key to use this feature."
            showAlert = true
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

                guard let currentUser = Auth.auth().currentUser else {
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

            } catch {
                print("❌ Sending message error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Sending message error: \(error.localizedDescription)"
                    self.isWaitingForResponse = false
                }
            }
        }
    }


    // MARK: - Message View
    private func messageView(for message: Message) -> some View {
        return HStack {
            if let recipe = message.parsedRecipe {
                if message.role == .user {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let imageURL = message.imageURL, let url = URL(string: imageURL) {
                            WebImage(url: url)
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
                    VStack(alignment: .leading, spacing: 10) {
                        if let title = recipe.title {
                            Text("\(title) 🥙")
                                .font(.custom("ArialRoundedMTBold", size: 20))
                                .bold()
                                .padding(.bottom, 5)
                        }

                        if !recipe.ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🥬【Ingredients】")
                                    .font(.custom("ArialRoundedMTBold", size: 18))
                                ForEach(recipe.ingredients) { ingredient in
                                    IngredientRow(ingredient: ingredient, addAction: addIngredientToShoppingList)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)

                            Button(action: {
                                if allIngredientsInCart(ingredients: recipe.ingredients) {
                                    addRemainingIngredientsToCart(ingredients: recipe.ingredients)
                                } else {
                                    addAllIngredientsToCart(ingredients: recipe.ingredients)
                                }
                            }) {
                                Text(allIngredientsInCart(ingredients: recipe.ingredients) ? "Add Remaining Ingredients to Cart" : "Add All Ingredients to Cart")
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(isButtonDisabled ? 0.3 : 0.8)
                            .disabled(isButtonDisabled)
                            .alert(isPresented: $showAlert) {
                                Alert(
                                    title: Text(alertTitle),
                                    message: Text(alertMessage),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }

                        if !recipe.steps.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🍳【Cooking Steps】")
                                    .font(.custom("ArialRoundedMTBold", size: 18))
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

                        if let link = recipe.link, let url = URL(string: link) {
                            Link(destination: url) {
                                HStack {
                                    Text("🔗 View Full Recipe")
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        } else {
                        }

                        if let tips = recipe.tips {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("👩🏻‍🍳【Friendly Reminder】")
                                    .font(.custom("ArialRoundedMTBold", size: 18))
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
                if message.role == .user {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let imageURL = message.imageURL, let url = URL(string: imageURL) {
                            WebImage(url: url)
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
    
    // MARK: - Detect Language
    func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        return language.rawValue
    }
    
    // MARK: - Recognize Food
    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
        
        // 加載 CoreML 模型
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("Failed to load model")
            completion("Unknown Food")
            return
        }
        
        // 創建 Vision 請求
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No results: \(error?.localizedDescription ?? "Unknown error")")
                completion("Unknown Food")
                return
            }
            
            DispatchQueue.main.async {
                let label = topResult.identifier
                let translatedLabel = TranslationDictionary.foodNames[label] ?? "Unknown"
                completion(translatedLabel)
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
    }
    
    // MARK: - Parse Recipe
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
                    
                    // 設置一個默認的 expirationDate，例如 5 天後
                    let expirationDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
                    
                    let ingredient = ParsedIngredient(name: name, quantity: quantityDouble, unit: unit, expirationDate: expirationDate)
                    ingredients.append(ingredient)
                    
                    print("Parsed Ingredient: \(ingredient)")
                } else {
                    let ingredient = ParsedIngredient(name: trimmedLine, quantity: 1.0, unit: "unit", expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())
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
        //UnitTest修改過後
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
        
        func autoCorrectMessageFormat(_ message: String) -> String {
            var correctedMessage = message
            
            if !correctedMessage.contains("\n【Recipe Link】") {
                correctedMessage = correctedMessage.replacingOccurrences(of: "【Recipe Link】", with: "\n【Recipe Link】")
            }
            
            return correctedMessage
        }

//        func processLinkLine(_ line: String) {
//            if let urlRange = line.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
//                link = String(line[urlRange])
//                print("Parsed Link: \(link!)")
//            } else {
//                if line.contains("Cannot provide") || line.contains("Sorry") {
//                    link = nil
//                    print("No link provided by assistant.")
//                } else {
//
//                    let potentialLink = line.trimmingCharacters(in: .whitespacesAndNewlines)
//                    if !potentialLink.isEmpty {
//                        link = "https://" + potentialLink
//                        print("Parsed Potential Link: \(link!)")
//                    } else {
//                        link = nil
//                    }
//                }
//            }
//        }
        
        func processTipsLine(_ line: String) {
            tips = (tips ?? "") + line + "\n"
            print("Parsed Tip: \(line)")
        }
       
        for line in lines {
            if line.contains("🥙") && line.contains("Recipe Name") {
                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cleanedLine = cleanedLine.replacingOccurrences(of: "Recipe Name:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                let pattern = #"(.+?)\s*\((.+?)\)\s*\((.+?)\)"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: cleanedLine, options: [], range: NSRange(location: 0, length: cleanedLine.utf16.count)),
                   match.numberOfRanges >= 4 {
                    let chineseNameRange = Range(match.range(at: 1), in: cleanedLine)
                    let pinyinRange = Range(match.range(at: 2), in: cleanedLine)
                    let englishNameRange = Range(match.range(at: 3), in: cleanedLine)
                    
                    if let chineseRange = chineseNameRange, let pinyinRange = pinyinRange, let englishRange = englishNameRange {
                        let chineseName = String(cleanedLine[chineseRange]).trimmingCharacters(in: .whitespaces)
                        let pinyin = String(cleanedLine[pinyinRange]).trimmingCharacters(in: .whitespaces)
                        let englishName = String(cleanedLine[englishRange]).trimmingCharacters(in: .whitespaces)
                        title = "\(chineseName) (\(englishName))"
                        
                        print("Parsed Title: \(title!)")
                    }
                } else {
                    title = cleanedLine
                    print("Parsed Title without English Name: \(title!)")
                }
                
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
    
    // MARK: - Remove Leading Number
    func removeLeadingNumber(from string: String) -> String {
        let pattern = #"^\s*\d+[\.\、]?\s*"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(string.startIndex..., in: string)
            return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        } else {
            return string
        }
    }
    
    // MARK: - Process Assistant Response
    func processAssistantResponse(_ responseMessage: Message) async {
        if let responseContent = responseMessage.content {
            var parsedRecipe = parseRecipe(from: responseContent)
            
            if var title = parsedRecipe.title {
                if isChinese(text: title) {
                    let translatedTitle = await withCheckedContinuation { continuation in
                        translate(text: title, from: "zh", to: "en") { translatedText in
                            continuation.resume(returning: translatedText)
                        }
                    }
                    if let translatedTitle = translatedTitle {
                        title = translatedTitle
                    }
                }
                if let link = await fetchRecipeLink(recipeName: title) {
                    parsedRecipe.link = link
                } else {
                    parsedRecipe.link = nil
                }
            }
            
            if let id = responseMessage.id {
                DispatchQueue.main.async {
                    self.parsedRecipes[id] = parsedRecipe
                }
            }
        }
    }
    
    // MARK: - Check if Text is Chinese
    func isChinese(text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }
    
    // MARK: - Add Ingredient to Shopping List
    func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
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

        if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
   
            DispatchQueue.main.async {
                self.foodItemStore.foodItems.append(newFoodItem)
            }

            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
            }

            return true
        } else {
            return false
        }
    }

    // MARK: - Check All Ingredients in Cart
    private func allIngredientsInCart(ingredients: [ParsedIngredient]) -> Bool {
        return ingredients.allSatisfy { ingredient in
            foodItemStore.foodItems.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() })
        }
    }
    
    // MARK: - Add Remaining Ingredients to Cart
    private func addRemainingIngredientsToCart(ingredients: [ParsedIngredient]) {
        var alreadyInCart = [String]()
        var addedToCart = [String]()
        
        for ingredient in ingredients {
            if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() }) {
                let success = addIngredientToShoppingList(ingredient)
                if success {
                    addedToCart.append(ingredient.name)
                }
            } else {
                alreadyInCart.append(ingredient.name)
            }
        }
        
        if addedToCart.isEmpty {
            alertTitle = "No New Ingredients Added"
            alertMessage = "All ingredients are already in your cart."
        } else {
            alertTitle = "Ingredients Added"
            alertMessage = "Added: \(addedToCart.joined(separator: ", "))"
            
            if !alreadyInCart.isEmpty {
                alertMessage += "\nAlready in cart: \(alreadyInCart.joined(separator: ", "))"
            }
        }
        showAlert = true
    }
    
    // MARK: - Add All Ingredients to Cart
    private func addAllIngredientsToCart(ingredients: [ParsedIngredient]) {
        var addedToCart = [String]()
        
        for ingredient in ingredients {
            if addIngredientToShoppingList(ingredient) {
                addedToCart.append(ingredient.name)
            }
        }
        alertTitle = "Ingredients Added"
        alertMessage = "Added: \(addedToCart.joined(separator: ", "))"
        showAlert = true
    }
    
    // MARK: - Extract Ingredients from Message
    func extractIngredients(from message: String) -> [String] {
        var ingredients: [String] = []
        let lines = message.components(separatedBy: "\n")
        var isIngredientSection = false
        
        for line in lines {
            if line.contains("【Ingredient】") {
                isIngredientSection = true
                continue
            } else if line.contains("【Cooking Instructions】") || line.contains("🍳") {
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
    
    // MARK: - Fetch Recipe Link
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
    
    // MARK: - Remove Ingredients Section
    func removeIngredientsSection(from message: String) -> String {
        var lines = message.components(separatedBy: "\n")
        var newLines: [String] = []
        var isIngredientSection = false
        
        for line in lines {
            if line.contains("【Ingredient】") {
                isIngredientSection = true
                continue
            } else if line.contains("【Cooking Instructions】") || line.contains("🍳") {
                isIngredientSection = false
            }
            
            if !isIngredientSection {
                newLines.append(line)
            }
        }
        return newLines.joined(separator: "\n")
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
                print("Added \(ingredient.name): \(success)")
            } else {
                alertMessage = "\(ingredient.name) already exists."
                print("\(ingredient.name) already exists.")
            }
            showAlert = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .foregroundColor(isAdded ? .gray : Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .bold()
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    if ingredient.quantity > 0 {
                        Text("Qty: \(ingredient.quantity, specifier: "%.2f") \(ingredient.unit)")
                            .font(.custom("ArialRoundedMTBold", size: 15))
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

struct MonsterAnimationView: View {
    @State private var moveRight = false
    
    var body: some View {
        ZStack {
            Image("runmonster")
                .resizable()
                .frame(width: 100, height: 100)
                .offset(x: moveRight ? 180 : -150)
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moveRight)
            
            Image("RUNchicken")
                .resizable()
                .frame(width: 60, height: 60)
                .offset(x: moveRight ? 120 : -280)
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moveRight)
        }
        .onAppear {
            moveRight = true
            print("Animation started")
        }
        .onDisappear {
            moveRight = false
            print("Animation stopped")
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                moveRight = true // Start animation
            }
            print("Animation started")
        }
        .onDisappear {
            withAnimation(nil) {
                moveRight = false 
            }
            print("Animation stopped")
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

