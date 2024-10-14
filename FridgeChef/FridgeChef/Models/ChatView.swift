//
//  ChatView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/10.
//
//MARK: 會辨識語言來做回答，但以英文為主
import SwiftUI
import PhotosUI
import Vision
import CoreML
import NaturalLanguage
import IQKeyboardManagerSwift
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    let firestoreService = FirestoreService()
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
    @State private var errorMessage: String?
    @State private var isButtonDisabled = false
    @State private var moveRight = true
    @State private var isFetchingLink: Bool = false
    @State private var isWaitingForResponse = false
    @State private var isSearchVisible = false
    @State private var selectedMessageID: String? = nil
    @State private var listener: ListenerRegistration?
    @State private var api = ChatGPTAPI(
        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA",
        systemPrompt: """
        You are a professional chef assistant capable of providing detailed recipes and cooking steps based on the ingredients, images, and descriptions provided by the user. Each reply must include the recipe name and a complete list of 【Ingredients】, along with a valid URL for the specified recipe. If a valid URL cannot be provided, please explicitly state so.
        
        🥙 Recipe Name: [English Name]
        
        🥬【Ingredients】 (All ingredients must be provided, including quantities and units, formatted as: Quantity Unit Ingredient Name)
        • 2 apples
        • 1 cup milk
        • ...
        
        🍳【Cooking Steps】 (Detailed description of each step, starting with a number and a period, direct description without adding extra titles, bold text, colons, or other symbols)
        1. Step one
        2. Step two
        3. Step three
        ...
        
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
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }
    
    var body: some View {
        NavigationView {
            if Auth.auth().currentUser != nil {
                ZStack {
                    // 漸層背景
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    
                    // 使用 GeometryReader 來實現背景的可點擊
                    GeometryReader { geometry in
                        VStack {
                            // 顯示背景圖片和文字
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
                            // 當點擊背景時，讓使用者能點擊進入輸入框
                            IQKeyboardManager.shared.resignFirstResponder()
                        }
                        
                        VStack {
                            ZStack {
                                // HStack 用於放置錯誤訊息和搜尋按鈕
                                HStack {
                                    if let errorMessage = errorMessage {
                                        Text(errorMessage)
                                            .foregroundColor(.red)
                                            .padding()
                                    }
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
                                
                                // Logo 放在 ZStack 的中心
                                Image("FridgeChefLogo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 300, height: 38)
                                    .padding(.top)
                            }

                            // 自定義搜尋框（從右邊滑入的動畫）
                            if isSearchVisible {
                                HStack(spacing: 10) { // 設置內部元素的間距
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.orange)
                                        .padding(.leading, 8) // 左側內邊距

                                    TextField("Search messages...", text: $searchText, onCommit: {
                                        // 當使用者按下回車鍵時，執行搜尋並清空搜尋框
                                        performSearch()
                                    })
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.vertical, 8)
                                    .padding(.trailing, 8) // 右側內邊距，避免與 xmark 圖標重疊

                                    if !searchText.isEmpty {
                                        Button(action: {
                                            self.searchText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.orange)
                                                .padding(.trailing, 8) // 右側內邊距
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).opacity(0.3))
                                .padding(.horizontal)
                                .transition(.move(edge: .trailing)) // 從右邊滑入
                            }

//                            ScrollViewReader { proxy in
//                                ScrollView {
//                                    VStack(alignment: .leading, spacing: 10) {
//                                        ForEach(filteredMessages) { message in
//                                            messageView(for: message)
//                                                .id(message.id) // 確保每個訊息有唯一的 ID
//                                        }
//                                    }
//                                    .onChange(of: messages.count) { _ in
//                                        if let lastMessage = messages.last {
//                                            // 這裡可以選擇是否保留滾動到最後一個訊息的行為
//                                             proxy.scrollTo(lastMessage.id, anchor: .bottom)
//                                        }
//                                    }
//                                    .onChange(of: selectedMessageID) { id in
//                                        if let id = id {
//                                            withAnimation {
//                                                proxy.scrollTo(id, anchor: .top) // 使用 .top 錨點滾動到訊息的開頭
//                                            }
//                                        }
//                                    }
//                                }
//                            }
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(filteredMessages) { message in
                                            messageView(for: message)
                                                .id(message.id) // 確保每個訊息有唯一的 ID
                                        }
                                    }
                                    .onChange(of: messages.count) { _ in
                                        // 滾動到最新的訊息
                                        if let lastMessage = messages.last, let id = lastMessage.id {
                                            withAnimation {
                                                proxy.scrollTo(id, anchor: .top)
                                            }
                                        }
                                    }
                                }
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
                                        .scaledToFit() // 確保圖片在框架內正確縮放
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                }
                                .padding(.leading, 15)
                                .fixedSize() // 防止按鈕被壓縮
                                .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                                    Button("Camera") { photoSource = .camera }
                                    Button("Photo Library") { photoSource = .photoLibrary }
                                }
                                
                                Spacer(minLength: 20) // 確保空間分佈
                                
                                PlaceholderTextEditor(text: $inputText, placeholder: "Want ideas? 🥙 ...")
                                    .frame(minHeight: 40, maxHeight: 60) // 與按鈕高度一致
                                
                                Spacer(minLength: 20) // 確保空間分佈
                                
                                Button(action: sendMessage) {
                                    Image(systemName: "paperplane.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                }
                                .padding(.trailing, 15)
                                .fixedSize() // 防止按鈕被壓縮
                            }
                            .padding(.bottom, 8)
                        }
                        
                    }
                    .onAppear {
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
        .fullScreenCover(item: $photoSource) { source in
            ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                .ignoresSafeArea()
        }
    }
    
    // 搜尋結果過濾
    var filteredMessages: [Message] {
           if searchText.isEmpty {
               return messages
           } else {
               // 根據使用者的搜尋文字過濾訊息內容，保持大小寫敏感
               return messages.filter { message in
                   message.content?.contains(searchText) ?? false
               }
           }
       }
    
    // 執行搜尋並清空搜尋框
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
        
        listener = firestoreService.listenForMessages(forUser: currentUser.uid) { result in
            switch result {
            case .success(let fetchedMessages):
                DispatchQueue.main.async {
                    // 比較現有的 messages 與 fetchedMessages，僅添加新的訊息
                    let newMessages = fetchedMessages.filter { fetchedMessage in
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
                    print("Fetched and updated messages: \(self.messages.count) messages") // 日誌
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
        // 確保有文字或圖片要傳送
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else { return }
        
        let messageText = inputText
        let messageImage = image
        inputText = ""
        image = nil
        
        isWaitingForResponse = true
        
        let timestamp = Date()
        
        if let messageImage = messageImage {
            // 上傳圖片並識別食材
            firestoreService.uploadImage(messageImage, path: "chat_images/\(UUID().uuidString).jpg") { result in
                switch result {
                case .success(let imageURL):
                    // 辨識圖片中的食材
                    recognizeFood(in: messageImage) { recognizedText in
                        let finalMessageText = "Identified ingredient: \(recognizedText).\nPlease provide detailed recipes and cooking steps."
                        let userMessage = Message(
                            id: nil, // 不手動設置 ID
                            role: .user,
                            content: finalMessageText,
                            imageURL: imageURL,
                            timestamp: timestamp,
                            parsedRecipe: nil
                        )
                        
                        // 保存到 Firestore，實時監聽器會自動更新 messages
                        self.saveMessageToFirestore(userMessage)
                        self.checkCachedResponseAndRespond(message: finalMessageText)
                    }
                case .failure(let error):
                    print("Failed to upload image: \(error.localizedDescription)")
                    // 如果圖片上傳失敗，只傳送文字訊息
                    let userMessage = Message(
                        id: nil, // 不手動設置 ID
                        role: .user,
                        content: messageText,
                        imageURL: nil,
                        timestamp: timestamp,
                        parsedRecipe: nil
                    )
                    // 保存到 Firestore，實時監聽器會自動更新 messages
                    self.saveMessageToFirestore(userMessage)
                    self.checkCachedResponseAndRespond(message: messageText)
                }
            }
        } else {
            // 如果沒有圖片，只傳送文字訊息
            let userMessage = Message(
                id: nil, // 不手動設置 ID
                role: .user,
                content: messageText,
                imageURL: nil,
                timestamp: timestamp,
                parsedRecipe: nil
            )
            // 保存到 Firestore，實時監聽器會自動更新 messages
            self.saveMessageToFirestore(userMessage)
            self.checkCachedResponseAndRespond(message: messageText)
        }
    }
    
    func checkCachedResponseAndRespond(message: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            self.isWaitingForResponse = false
            return
        }
        
        firestoreService.getCachedResponse(forUser: currentUser.uid, message: message) { result in
            switch result {
            case .success(let cachedResponse):
                if let cachedResponse = cachedResponse {
                    print("🔍 使用緩存回應: \(cachedResponse.response)") // 新增日誌
                    // 使用緩存的回應
                    let assistantMessage = Message(
                        id: nil, // 讓 Firestore 自動生成 ID
                        role: .assistant,
                        content: cachedResponse.response,
                        imageURL: nil,
                        timestamp: Date(),
                        parsedRecipe: self.parseRecipe(from: cachedResponse.response)
                    )
                    
                    // 保存到 Firestore，實時監聽器會自動更新 messages
                    self.saveMessageToFirestore(assistantMessage)
                    self.isWaitingForResponse = false
                } else {
                    print("🔄 沒有找到緩存回應，呼叫 API...") // 新增日誌
                    // 沒有緩存，調用API
                    self.sendMessageToAssistant(message)
                }
            case .failure(let error):
                print("❌ 獲取緩存回應時出錯: \(error)") // 新增日誌
                // 如果出錯，仍然調用API
                self.sendMessageToAssistant(message)
            }
        }
    }

    // MARK: - Send Message to Assistant
    func sendMessageToAssistant(_ messageText: String) {
        guard !messageText.isEmpty else { return }
        let messageToSend = messageText

        Task {
            do {
                print("📤 正在呼叫 API 並發送訊息: \(messageToSend)") // 新增日誌
                let responseText = try await api.sendMessage(messageToSend)
                print("📥 收到 API 回應: \(responseText)") // 新增日誌

                let parsedRecipe = parseRecipe(from: responseText) // 解析食譜

                // 保存到緩存
                guard let currentUser = Auth.auth().currentUser else {
                    print("🔒 沒有用戶登錄。")
                    self.isWaitingForResponse = false
                    return
                }

                firestoreService.saveCachedResponse(forUser: currentUser.uid, message: messageText, response: responseText) { result in
                    switch result {
                    case .success():
                        print("✅ 緩存回應已保存。")
                    case .failure(let error):
                        print("❌ 無法保存緩存回應: \(error)")
                    }
                }

                // 保存到 chats 集合，讓實時監聽器更新 messages
                let responseMessage = Message(
                    id: nil, // 讓 Firestore 自動生成 ID
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
                print("❌ 發送訊息時出錯: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "發送訊息時出錯: \(error.localizedDescription)"
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
                        // 顯示食譜名稱
                        if let title = recipe.title {
                            Text("\(title) 🥙")
                                .font(.title3)
                                .bold()
                                .padding(.bottom, 5)
                        }

                        // 顯示食材列表
                        if !recipe.ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🥬【Ingredients】")
                                    .font(.headline)
                                ForEach(recipe.ingredients) { ingredient in
                                    IngredientRow(ingredient: ingredient, addAction: addIngredientToShoppingList)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)

                            // 添加按鈕
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

                        // 顯示烹飪步驟
                        if !recipe.steps.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🍳【Cooking Steps】")
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
                                    Text("🔗 View Full Recipe")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        } else {
                            Text("Oops! Can't share the recipe link right now. Got other ingredients or meals in mind? \nLet me help you find something tasty! 👨🏻‍🌾")
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }

                        // 顯示貼心提醒
                        if let tips = recipe.tips {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("👩🏻‍🍳【Friendly Reminder】")
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
        
        // 嘗試加載 CoreML 模型
        guard let model = try? VNCoreMLModel(for: Food().model) else {
            print("Failed to load model")
            completion("Unknown Food")
            return
        }
        
        // 創建 Vision 請求
        let request = VNCoreMLRequest(model: model) { request, error in
            // 處理請求結果
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("No results: \(error?.localizedDescription ?? "Unknown error")")
                completion("Unknown Food")
                return
            }
            
            // 在主線程上返回識別結果
            DispatchQueue.main.async {
                let label = topResult.identifier
                completion(label)
            }
        }
        
        // 將 UIImage 轉換為 CIImage
        guard let ciImage = CIImage(image: image) else {
            print("Unable to create \(CIImage.self) from \(image).")
            completion("Unknown Food")
            return
        }
        
        // 創建處理器並執行請求
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
                    
                    print("Parsed Ingredient: \(ingredient)") // 調試日誌
                } else {
                    // 如果无法解析，设置默认的 quantity 和 expirationDate
                    let ingredient = ParsedIngredient(name: trimmedLine, quantity: 1.0, unit: "unit", expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())
                    ingredients.append(ingredient)
                    
                    print("Parsed Ingredient with Defaults: \(ingredient)") // 調試日誌
                }
            }
        }
        
        func processStepsLine(_ line: String) {
            var trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                trimmedLine = removeLeadingNumber(from: trimmedLine)
                steps.append(trimmedLine)
                
                print("Parsed Step: \(trimmedLine)") // 調試日誌
            }
        }
        
        func processLinkLine(_ line: String) {
            if let urlRange = line.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
                link = String(line[urlRange])
                print("Parsed Link: \(link!)") // 調試日誌
            } else {
                // 如果无法提取链接，检查是否有提示无法提供链接的文本
                if line.contains("Cannot provide") || line.contains("Sorry") {
                    link = nil
                    print("No link provided by assistant.") // 調試日誌
                } else {
                    // 如果有其他文本，可能是一个 URL，但没有以 http 开头，尝试补全
                    let potentialLink = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !potentialLink.isEmpty {
                        link = "https://" + potentialLink
                        print("Parsed Potential Link: \(link!)") // 調試日誌
                    } else {
                        link = nil
                    }
                }
            }
        }
        
        func processTipsLine(_ line: String) {
            tips = (tips ?? "") + line + "\n"
            print("Parsed Tip: \(line)") // 調試日誌
        }
        
        // 主循環
        for line in lines {
            if line.contains("🥙") && line.contains("Recipe Name") {
                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                cleanedLine = cleanedLine.replacingOccurrences(of: "Recipe Name:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 使用正則表達式提取中文名稱、拼音和英文名稱
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
                        
                        print("Parsed Title: \(title!)") // 調試日誌
                    }
                } else {
                    title = cleanedLine
                    print("Parsed Title without English Name: \(title!)") // 調試日誌
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
        
        // 如果未成功解析，將整個消息內容作為未解析內容
        if !isParsed {
            unparsedContent = message
            print("Parsed Recipe with Unparsed Content: \(ParsedRecipe.self)") // 調試日誌
        }
        
        let parsedRecipe = ParsedRecipe(
               title: title,
               ingredients: ingredients,
               steps: steps,
               link: link,
               tips: tips,
               unparsedContent: unparsedContent
           )
        
        print("Final Parsed Recipe: \(parsedRecipe)") // 調試日誌
        
        return parsedRecipe
    }
    
    // MARK: - Remove Leading Number
    func removeLeadingNumber(from string: String) -> String {
        let pattern = #"^\s*\d+[\.\、]?\s*"#  // 匹配数字后跟 "."、"、" 或空格
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
            // 添加到本地数组
            DispatchQueue.main.async {
                self.foodItemStore.foodItems.append(newFoodItem)
            }

            // 保存到 Firestore
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
                switch result {
                case .success():
                    print("Food item successfully added to Firestore.")
                case .failure(let error):
                    print("Failed to add food item to Firestore: \(error.localizedDescription)")
                }
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
        
        // 根據結果更新 Alert 內容
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
        
        // 顯示 Alert
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
        
        // 顯示已添加的食材
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
    
    // MARK: - Fetch Recipe Link
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
    
    // MARK: - Remove Ingredients Section
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
    
    // MARK: - Send Message to API
//    func sendMessageToAPI(message: String) {
//        Task {
//            do {
//                let responseText = try await api.sendMessage(message)
//                let responseMessage = Message(id: UUID().uuidString, role: .assistant, content: responseText, imageURL: nil, timestamp: Date())
//                DispatchQueue.main.async {
//                    self.messages.append(responseMessage)
//                    self.saveMessageToFirestore(responseMessage)
//                    self.isWaitingForResponse = false
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Message sending error: \(error.localizedDescription)"
//                    self.isWaitingForResponse = false
//                }
//            }
//        }
//    }
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

struct MonsterAnimationView: View {
    @State private var moveRight = false
    
    var body: some View {
        ZStack {
            Image("runmonster")
                .resizable()
                .frame(width: 100, height: 100)
                .offset(x: moveRight ? 180 : -150) // runmonster 在 CHICKEN 後面追逐
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moveRight)
            
            Image("RUNchicken")
                .resizable()
                .frame(width: 60, height: 60)
                .offset(x: moveRight ? 120 : -280) // CHICKEN 從左到右移動
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moveRight)
        }
        .onAppear {
            moveRight = true
            print("Animation started")
        }
        .onDisappear {
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

////MARK: 會辨識語言來做回答，但以英文為主this one can save ingredients into Firestore
//import SwiftUI
//import PhotosUI
//import Vision
//import CoreML
//import NaturalLanguage
//import IQKeyboardManagerSwift
//import FirebaseAuth
//import FirebaseFirestore
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
//    let firestoreService = FirestoreService()
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var isFetchingLink: Bool = false
//    @State private var isWaitingForResponse = false
//    @State private var parsedRecipes: [UUID: ParsedRecipe] = [:]
//    @State private var inputText = ""
//    @State private var messages: [Message] = []
//    @State private var showPhotoOptions = false
//    @State private var photoSource: PhotoSource?
//    @State private var image: UIImage?
//    @State private var showChangePhotoDialog = false
//    @State private var errorMessage: String?
//    @State private var isButtonDisabled = false
//    @State private var moveRight = true
//    @State private var api = ChatGPTAPI(
//        apiKey: "sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA",
//        systemPrompt: """
//        You are a professional chef assistant capable of providing detailed recipes and cooking steps based on the ingredients, images, and descriptions provided by the user. Each reply must include the recipe name and a complete list of 【Ingredients】, along with a valid URL for the specified recipe. If a valid URL cannot be provided, please explicitly state so.
//
//        🥙 Recipe Name: [English Name]
//
//        🥬【Ingredients】 (All ingredients must be provided, including quantities and units, formatted as: Quantity Unit Ingredient Name)
//        • 2 apples
//        • 1 cup milk
//        • ...
//
//        🍳【Cooking Steps】 (Detailed description of each step, starting with a number and a period, direct description without adding extra titles, bold text, colons, or other symbols)
//        1. Step one
//        2. Step two
//        3. Step three
//        ...
//
//        🔗【Recipe Link】
//        (Please provide a valid URL related to the recipe the user asked for.)
//
//        👩🏻‍🍳【Friendly Reminder】
//        (Here you can provide a friendly reminder or answer the user's questions.)
//
//        Bon appetit 🍽️
//
//        **Notes:**
//        - Respond in the user's language based on their input. Do not specify language in the system prompt.
//        - Do not add extra titles, bold text, colons, or other symbols in the steps.
//        - Each step should be a complete sentence, directly describing the action.
//        - Additionally, you can recommend related recipes and detailed cooking methods based on the user's ideas.
//        - Strictly follow the above format without adding any extra content or changing the format.
//        """
//    )
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
//                    LinearGradient(
//                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .opacity(0.4)
//                    .edgesIgnoringSafeArea(.all)
//
//                    // 使用 GeometryReader 來實現背景的可點擊
//                    GeometryReader { geometry in
//                        VStack {
//                            // 顯示背景圖片和文字
//                            if messages.isEmpty {
//                                VStack {
//                                    Image("Chatmonster")
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(width: 300, height: 300)
//                                }
//                                .frame(width: geometry.size.width, height: geometry.size.height)
//                                .background(Color.clear)
//                            }
//                        }
//                        .onTapGesture {
//                            // 當點擊背景時，讓使用者能點擊進入輸入框
//                            IQKeyboardManager.shared.resignFirstResponder()
//                        }
//                    }
//
//                VStack {
//                    if let errorMessage = errorMessage {
//                        Text(errorMessage)
//                            .foregroundColor(.red)
//                            .padding()
//                    }
//
//                    Image("FridgeChefLogo")
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
//                        ZStack {
//                            Image("runmonster")
//                                .resizable()
//                                .frame(width: 100, height: 100)
//                                .offset(x: moveRight ? 180 : -150) // runmonster 在 CHICKEN 後面追逐
//                                .animation(
//                                    Animation.easeInOut(duration: 2.0)
//                                        .repeatForever(autoreverses: false)
//                                )
//
//                            Image("RUNchicken")
//                                .resizable()
//                                .frame(width: 60, height: 60)
//                                .offset(x: moveRight ? 120 : -280)// CHICKEN 從左到右移動
//                                .animation(
//                                    Animation.easeInOut(duration: 2.0)
//                                        .repeatForever(autoreverses: false)
//                                )
//                        }
//                        .onAppear {
//                            moveRight.toggle() // 切換動畫方向
//                        }
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
//                            .confirmationDialog("Wanna Change?", isPresented: $showChangePhotoDialog, titleVisibility: .visible) {
//                                Button("Change") {
//                                    showPhotoOptions = true
//                                }
//                                Button("Remove", role: .destructive) {
//                                    self.image = nil
//                                }
//                                Button("Cancel", role: .cancel) {}
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
//                        .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions, titleVisibility: .visible) {
//                            Button("Camera") { photoSource = .camera }
//                            Button("Photo Library") { photoSource = .photoLibrary }
//                        }
//
//                        Spacer(minLength: 20) // Ensures space distribution
//
//                        PlaceholderTextEditor(text: $inputText, placeholder: "Want ideas? 🥙 ...")
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
//
//    }
//
//    func detectLanguage(for text: String) -> String? {
//        let recognizer = NLLanguageRecognizer()
//        recognizer.processString(text)
//        guard let language = recognizer.dominantLanguage else { return nil }
//        return language.rawValue
//    }
//
//    func recognizeFood(in image: UIImage, completion: @escaping (String) -> Void) {
//
//        // 嘗試加載 CoreML 模型
//        guard let model = try? VNCoreMLModel(for: Food().model) else {
//            print("Failed to load model")
//            completion("Unknown Food")
//            return
//        }
//
//        // 創建 Vision 請求
//        let request = VNCoreMLRequest(model: model) { request, error in
//            // 處理請求結果
//            guard let results = request.results as? [VNClassificationObservation],
//                  let topResult = results.first else {
//                print("No results: \(error?.localizedDescription ?? "Unknown error")")
//                completion("Unknown Food")
//                return
//            }
//
//            // 在主線程上返回識別結果
//            DispatchQueue.main.async {
//                let label = topResult.identifier
//                completion(label)
//            }
//        }
//
//        // 將 UIImage 轉換為 CIImage
//        guard let ciImage = CIImage(image: image) else {
//            print("Unable to create \(CIImage.self) from \(image).")
//            completion("Unknown Food")
//            return
//        }
//
//        // 創建處理器並執行請求
//        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Failed to perform classification.\n\(error.localizedDescription)")
//                completion("Unknown Food")
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
//            if !trimmedLine.isEmpty && trimmedLine != "..." {
//                let pattern = #"^(\d+\.?\d*)\s*([^\d\s]+)?\s+(.+)$"#
//                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
//                   let match = regex.firstMatch(in: trimmedLine, options: [], range: NSRange(location: 0, length: trimmedLine.utf16.count)) {
//
//                    let quantityRange = Range(match.range(at: 1), in: trimmedLine)
//                    let unitRange = Range(match.range(at: 2), in: trimmedLine)
//                    let nameRange = Range(match.range(at: 3), in: trimmedLine)
//
//                    let quantityString = quantityRange.map { String(trimmedLine[$0]) } ?? "1.0"
//                    let quantityDouble = Double(quantityString) ?? 1.0
//                    let unit = unitRange.map { String(trimmedLine[$0]) } ?? "unit"
//                    let name = nameRange.map { String(trimmedLine[$0]) } ?? trimmedLine
//
//                    // 設置一個默認的 expirationDate，例如 5 天後
//                    let expirationDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
//
//                    let ingredient = ParsedIngredient(name: name, quantity: quantityDouble, unit: unit, expirationDate: expirationDate)
//                    ingredients.append(ingredient)
//
//                    print("Parsed Ingredient: \(ingredient)") // 調試日誌
//                } else {
//                    // 如果无法解析，设置默认的 quantity 和 expirationDate
//                    let ingredient = ParsedIngredient(name: trimmedLine, quantity: 1.0, unit: "unit", expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())
//                    ingredients.append(ingredient)
//
//                    print("Parsed Ingredient with Defaults: \(ingredient)") // 調試日誌
//                }
//            }
//        }
//
//        func processStepsLine(_ line: String) {
//            var trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
//            if !trimmedLine.isEmpty {
//                trimmedLine = removeLeadingNumber(from: trimmedLine)
//                steps.append(trimmedLine)
//
//                print("Parsed Step: \(trimmedLine)") // 調試日誌
//            }
//        }
//
//        func processLinkLine(_ line: String) {
//            if let urlRange = line.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
//                link = String(line[urlRange])
//                print("Parsed Link: \(link!)") // 調試日誌
//            } else {
//                // 如果无法提取链接，检查是否有提示无法提供链接的文本
//                if line.contains("Cannot provide") || line.contains("Sorry") {
//                    link = nil
//                    print("No link provided by assistant.") // 調試日誌
//                } else {
//                    // 如果有其他文本，可能是一个 URL，但没有以 http 开头，尝试补全
//                    let potentialLink = line.trimmingCharacters(in: .whitespacesAndNewlines)
//                    if !potentialLink.isEmpty {
//                        link = "https://" + potentialLink
//                        print("Parsed Potential Link: \(link!)") // 調試日誌
//                    } else {
//                        link = nil
//                    }
//                }
//            }
//        }
//
//        func processTipsLine(_ line: String) {
//            tips = (tips ?? "") + line + "\n"
//            print("Parsed Tip: \(line)") // 調試日誌
//        }
//
//        // 主循環
//        for line in lines {
//            if line.contains("🥙") && line.contains("Recipe Name") {
//                var cleanedLine = line.replacingOccurrences(of: "🥙 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//                cleanedLine = cleanedLine.replacingOccurrences(of: "Recipe Name:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//
//                // 使用正則表達式提取中文名稱、拼音和英文名稱
//                let pattern = #"(.+?)\s*\((.+?)\)\s*\((.+?)\)"#
//                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
//                   let match = regex.firstMatch(in: cleanedLine, options: [], range: NSRange(location: 0, length: cleanedLine.utf16.count)),
//                   match.numberOfRanges >= 4 {
//                    let chineseNameRange = Range(match.range(at: 1), in: cleanedLine)
//                    let pinyinRange = Range(match.range(at: 2), in: cleanedLine)
//                    let englishNameRange = Range(match.range(at: 3), in: cleanedLine)
//
//                    if let chineseRange = chineseNameRange, let pinyinRange = pinyinRange, let englishRange = englishNameRange {
//                        let chineseName = String(cleanedLine[chineseRange]).trimmingCharacters(in: .whitespaces)
//                        let pinyin = String(cleanedLine[pinyinRange]).trimmingCharacters(in: .whitespaces)
//                        let englishName = String(cleanedLine[englishRange]).trimmingCharacters(in: .whitespaces)
//                        title = "\(chineseName) (\(englishName))"
//
//                        print("Parsed Title: \(title!)") // 調試日誌
//                    }
//                } else {
//                    title = cleanedLine
//                    print("Parsed Title without English Name: \(title!)") // 調試日誌
//                }
//
//                isParsed = true
//                continue
//            }
//
//            if line.contains("【Ingredients】") {
//                currentSection = "ingredients"
//                isParsed = true
//                continue
//            }
//            if line.contains("【Cooking Steps】") {
//                currentSection = "steps"
//                isParsed = true
//                continue
//            }
//            if line.contains("【Recipe Link】") {
//                currentSection = "link"
//                isParsed = true
//                continue
//            }
//            if line.contains("【Friendly Reminder】") {
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
//        // 如果未成功解析，將整個消息內容作為未解析內容
//        if !isParsed {
//            unparsedContent = message
//            print("Parsed Recipe with Unparsed Content: \(ParsedRecipe.self)") // 調試日誌
//        }
//
//        let parsedRecipe = ParsedRecipe(
//            title: title,
//            ingredients: ingredients,
//            steps: steps,
//            link: link,
//            tips: tips,
//            unparsedContent: unparsedContent
//        )
//
//        print("Final Parsed Recipe: \(ParsedRecipe.self)") // 調試日誌
//
//        return parsedRecipe
//    }
//
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
//                                Text("🥬【Ingredients】")
//                                    .font(.headline)
//                                ForEach(recipe.ingredients) { ingredient in
//                                    IngredientRow(ingredient: ingredient, addAction: addIngredientToShoppingList)
//                                }
//                            }
//                            .padding()
//                            .background(Color.purple.opacity(0.1))
//                            .cornerRadius(10)
//
//                            // 一個按鈕，根據條件改變文本和動作
//                            Button(action: {
//                                if allIngredientsInCart(ingredients: recipe.ingredients) {
//                                    addRemainingIngredientsToCart(ingredients: recipe.ingredients)
//                                } else {
//                                    addAllIngredientsToCart(ingredients: recipe.ingredients)
//                                }
//                            }) {
//                                Text(allIngredientsInCart(ingredients: recipe.ingredients) ? "Add Remaining Ingredients to Cart" : "Add All Ingredients to Cart")
//                                    .bold()
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .background(Color.orange)
//                                    .cornerRadius(10)
//                            }
//                            .frame(maxWidth: .infinity) // 按鈕居中
//                            .opacity(isButtonDisabled ? 0.3 : 0.8) // 按鈕的透明度
//                            .disabled(isButtonDisabled) // 按鈕的禁用狀態
//                            .alert(isPresented: $showAlert) {
//                                Alert(
//                                    title: Text(alertTitle),
//                                    message: Text(alertMessage),
//                                    dismissButton: .default(Text("OK"))
//                                )
//                            }
//                        }
//
//                        // 顯示烹飪步驟
//                        if !recipe.steps.isEmpty {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("🍳【Cooking Steps】")
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
//                                    Text("🔗 View Full Recipe")
//                                        .font(.headline)
//                                        .foregroundColor(.blue)
//                                }
//                                .padding()
//                                .background(Color.blue.opacity(0.1))
//                                .cornerRadius(10)
//                            }
//                        } else {
//                            Text("Oops! Can't share the recipe link right now. Got other ingredients or meals in mind? \nLet me help you find something tasty! 👨🏻‍🌾")
////                            "抱歉，我目前無法提供該料理的食譜連結。如果您有任何其他食材或菜式需要幫忙，歡迎隨時告訴我！讓我來幫助您找到更多美味的食譜。👨🏻‍🌾"
//                                .padding()
//                                .background(Color.gray.opacity(0.1))
//                                .cornerRadius(10)
//                        }
//
//                        // 顯示貼心提醒
//                        if let tips = recipe.tips {
//                            VStack(alignment: .leading, spacing: 5) {
//                                Text("👩🏻‍🍳【Friendly Reminder】")
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
//    @State private var showAlert = false
//    @State private var alertTitle = ""
//    @State private var alertMessage = ""
//
//    // 判斷所有食材是否已經加入購物車
//    private func allIngredientsInCart(ingredients: [ParsedIngredient]) -> Bool {
//        return ingredients.allSatisfy { ingredient in
//            foodItemStore.foodItems.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() })
//        }
//    }
//
//    // 添加剩餘食材的方法
//    private func addRemainingIngredientsToCart(ingredients: [ParsedIngredient]) {
//        var alreadyInCart = [String]()
//        var addedToCart = [String]()
//
//        for ingredient in ingredients {
//            if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == ingredient.name.lowercased() }) {
//                let success = addIngredientToShoppingList(ingredient)
//                if success {
//                    addedToCart.append(ingredient.name)
//                }
//            } else {
//                alreadyInCart.append(ingredient.name)
//            }
//        }
//
//        // 根據結果更新 Alert 內容
//        if addedToCart.isEmpty {
//            alertTitle = "No New Ingredients Added"
//            alertMessage = "All ingredients are already in your cart."
//        } else {
//            alertTitle = "Ingredients Added"
//            alertMessage = "Added: \(addedToCart.joined(separator: ", "))"
//
//            if !alreadyInCart.isEmpty {
//                alertMessage += "\nAlready in cart: \(alreadyInCart.joined(separator: ", "))"
//            }
//        }
//
//        // 顯示 Alert
//        showAlert = true
//    }
//
//    // 添加所有食材的方法
//    private func addAllIngredientsToCart(ingredients: [ParsedIngredient]) {
//        var addedToCart = [String]()
//
//        for ingredient in ingredients {
//            if addIngredientToShoppingList(ingredient) {
//                addedToCart.append(ingredient.name)
//            }
//        }
//
//        // 顯示已添加的食材
//        alertTitle = "Ingredients Added"
//        alertMessage = "Added: \(addedToCart.joined(separator: ", "))"
//        showAlert = true
//    }
//
//    func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
//        guard let currentUser = Auth.auth().currentUser else {
//            print("No user is currently logged in.")
//            return false
//        }
//
//        let newFoodItem = FoodItem(
//            id: UUID().uuidString,
//            name: ingredient.name,
//            quantity: ingredient.quantity,
//            unit: ingredient.unit,
//            status: .toBuy,
//            daysRemaining: Calendar.current.dateComponents([.day], from: Date(), to: ingredient.expirationDate).day ?? 0,
//            expirationDate: ingredient.expirationDate,
//            imageURL: nil
//        )
//
//        if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
//            foodItemStore.foodItems.append(newFoodItem)
//
//            // Save to Firestore
//            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
//                switch result {
//                case .success():
//                    print("Food item successfully added to Firebase.")
//                case .failure(let error):
//                    print("Failed to add food item to Firebase: \(error.localizedDescription)")
//                }
//            }
//
//            return true
//        } else {
//            return false
//        }
//    }
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
//                                finalMessageText +=
//                                "Identified ingredient: \(recognizedText).\nPlease provide detailed recipes and cooking steps."
//                            } else {
//                                finalMessageText =
//                                "Identified ingredient: \(recognizedText).\nPlease provide detailed recipes and cooking steps."
//                            }
//
//                            // 更新使用者訊息
//                            if !finalMessageText.isEmpty {
//                                let updatedUserMessage = Message(role: .user, content: finalMessageText, image: nil)
//                                self.messages.append(updatedUserMessage)
//                            }
//
//                            // 語言檢測
//                            let detectedLanguage = detectLanguage(for: finalMessageText) ?? "zh-Hant"
//                            let languageDirective: String
//
//                            if detectedLanguage.starts(with: "en") {
//                                languageDirective = "Please respond in English."
//                            } else if detectedLanguage.starts(with: "zh-Hant") {
//                                languageDirective = "請用中文回覆。"
//                            } else {
//                                languageDirective = ""
//                            }
//
//                            // 添加語言指令到訊息
//                            let messageToSend = "\(languageDirective)\n\(finalMessageText)"
//
//                            print("Sending message to API: \(messageToSend)") // 日誌
//
//                            // 發送訊息給 API
//                            Task {
//                                do {
//                                    let responseText = try await api.sendMessage(messageToSend) // 使用 messageToSend
//                                    let responseMessage = Message(role: .assistant, content: responseText, image: nil)
//                                    DispatchQueue.main.async {
//                                        self.messages.append(responseMessage)
//                                        self.errorMessage = nil
//                                        self.isWaitingForResponse = false
//                                    }
//
//                                    print("Received response: \(responseText)") // 日誌
//
//                                    // 解析食譜並獲取連結
//                                    if let responseContent = responseMessage.content {
//                                        let parsedRecipe = parseRecipe(from: responseContent)
//                                        if parsedRecipe.link == nil, let title = parsedRecipe.title {
//                                            // 提取最後一組括號內的英文名稱進行搜索
//                                            let pattern = #"(.+)\s*\(([^)]+)\)"#
//                                            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
//                                               let match = regex.matches(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count)).last,
//                                               match.numberOfRanges >= 3 {
//                                                let englishNameRange = Range(match.range(at: 2), in: title)
//                                                if let range = englishNameRange {
//                                                    let englishName = String(title[range])
//                                                    print("Extracted English Name for API Search: \(englishName)") // 日誌
//                                                    Task {
//                                                        if let link = await fetchRecipeLink(recipeName: englishName) {
//                                                            DispatchQueue.main.async {
//                                                                var updatedParsedRecipe = parsedRecipe
//                                                                updatedParsedRecipe.link = link
//                                                                self.parsedRecipes[responseMessage.id] = updatedParsedRecipe
//                                                            }
//                                                        } else {
//                                                            DispatchQueue.main.async {
//                                                                self.parsedRecipes[responseMessage.id] = parsedRecipe
//                                                            }
//                                                        }
//                                                    }
//                                                }
//                                            } else {
//                                                print("Failed to extract English name from title: \(title)") // 日誌
//                                            }
//                                        } else {
//                                            DispatchQueue.main.async {
//                                                self.parsedRecipes[responseMessage.id] = parsedRecipe
//                                            }
//                                        }
//                                    }
//                                } catch {
//                                    print("Message sending error:\(error)")
//                                    DispatchQueue.main.async {
//                                        self.errorMessage = "Message sending error: \(error.localizedDescription)"
//                                        self.isWaitingForResponse = false
//                                    }
//                                }
//                            }
//                        }
//                    }
//                } else {
//                    // 沒有圖片，直接發送訊息
//                    if !finalMessageText.isEmpty {
//                        // 語言檢測
//                        let detectedLanguage = detectLanguage(for: finalMessageText) ?? "zh-Hant"
//                        let languageDirective: String
//
//                        if detectedLanguage.starts(with: "en") {
//                            languageDirective = "Please respond in English."
//                        } else if detectedLanguage.starts(with: "zh") {
//                            languageDirective = "請用中文回覆。"
//                        } else {
//                            languageDirective = ""
//                        }
//
//                        // 添加語言指令到訊息
//                        let messageToSend = "\(languageDirective)\n\(finalMessageText)"
//
//                        print("Sending message to API: \(messageToSend)") // 日誌
//
//                        let responseText = try await api.sendMessage(messageToSend) // 使用 messageToSend
//                        let responseMessage = Message(role: .assistant, content: responseText, image: nil)
//                        DispatchQueue.main.async {
//                            self.messages.append(responseMessage)
//                            self.errorMessage = nil
//                            self.isWaitingForResponse = false
//                        }
//
//                        print("Received response: \(responseText)") // 日誌
//
//                        // 解析食譜並獲取連結
//                        if let responseContent = responseMessage.content {
//                            let parsedRecipe = parseRecipe(from: responseContent)
//
//                            // 使用最後一組括號內的英文名稱進行搜索
//                            if let title = parsedRecipe.title {
//                                let pattern = #"(.+)\s*\(([^)]+)\)"#
//                                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
//                                   let match = regex.matches(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count)).last,
//                                   match.numberOfRanges >= 3 {
//                                    let englishNameRange = Range(match.range(at: 2), in: title)
//                                    if let range = englishNameRange {
//                                        let englishName = String(title[range])
//                                        print("Extracted English Name for API Search: \(englishName)") // 日誌
//                                        Task {
//                                            if let link = await fetchRecipeLink(recipeName: englishName) {
//                                                DispatchQueue.main.async {
//                                                    var updatedParsedRecipe = parsedRecipe
//                                                    updatedParsedRecipe.link = link
//                                                    self.parsedRecipes[responseMessage.id] = updatedParsedRecipe
//                                                }
//                                            } else {
//                                                DispatchQueue.main.async {
//                                                    self.parsedRecipes[responseMessage.id] = parsedRecipe
//                                                }
//                                            }
//                                        }
//                                    }
//                                } else {
//                                    print("Failed to extract English name from title: \(title)") // 日誌
//                                }
//                            }
//                        }
//                    }
//                }
//            } catch {
//                print("Message sending error:\(error)")
//                DispatchQueue.main.async {
//                    self.errorMessage = "Error while sending message：\(error.localizedDescription)"
//                    self.isWaitingForResponse = false
//                }
//            }
//        }
//    }
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
//                    self.errorMessage = "Message sending error:\(error.localizedDescription)"
//                    self.isWaitingForResponse = false
//                }
//            }
//        }
//    }
//
//    func processAssistantResponse(_ responseMessage: Message) async {
//        if let responseContent = responseMessage.content {
//            var parsedRecipe = parseRecipe(from: responseContent)
//
//            if var title = parsedRecipe.title {
//                // If the title is in Chinese, translate it to English
//                if isChinese(text: title) {
//                    // Use your translation function to get the English title
//                    let translatedTitle = await withCheckedContinuation { continuation in
//                        translate(text: title, from: "zh", to: "en") { translatedText in
//                            continuation.resume(returning: translatedText)
//                        }
//                    }
//                    if let translatedTitle = translatedTitle {
//                        title = translatedTitle
//                    }
//                }
//                // Fetch the link from Spoonacular API using the English title
//                if let link = await fetchRecipeLink(recipeName: title) {
//                    parsedRecipe.link = link
//                } else {
//                    // Handle the case where no link is found
//                    parsedRecipe.link = nil
//                }
//            }
//
//            DispatchQueue.main.async {
//                self.parsedRecipes[responseMessage.id] = parsedRecipe
//            }
//        }
//    }
//
//    func isChinese(text: String) -> Bool {
//        for scalar in text.unicodeScalars {
//            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
//                return true
//            }
//        }
//        return false
//    }
//
//}
//
//struct IngredientRow: View {
//    var ingredient: ParsedIngredient
//    var addAction: (ParsedIngredient) -> Bool
//    @EnvironmentObject var foodItemStore: FoodItemStore
//
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//
//    var body: some View {
//        let isAdded = foodItemStore.foodItems.contains { $0.name.lowercased() == ingredient.name.lowercased() }
//
//        Button(action: {
//            if !isAdded {
//                let success = addAction(ingredient)
//                alertMessage = success ? "\(ingredient.name) add to your Grocery List 🛒" : "\(ingredient.name) already exists!"
//                print("Added \(ingredient.name): \(success)") // Debug
//            } else {
//                alertMessage = "\(ingredient.name) already exists."
//                print("\(ingredient.name) already exists.") // Debug
//            }
//            showAlert = true
//        }) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(ingredient.name)
//                        .foregroundColor(isAdded ? .gray : Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                        .bold()
//                        .lineLimit(nil)
//                        .fixedSize(horizontal: false, vertical: true)
//                    if ingredient.quantity > 0 { // 改為檢查 quantity > 0
//                        Text("Qty：\(ingredient.quantity, specifier: "%.2f") \(ingredient.unit)") // 格式化為兩位小數
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                    }
//                }
//                Spacer()
//                Image(systemName: isAdded ? "checkmark.circle.fill" : "cart.badge.plus.fill")
//                    .foregroundColor(isAdded ? .green : Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//            }
//            .padding(.vertical, 5)
//        }
//        .buttonStyle(PlainButtonStyle())
//        .disabled(isAdded)
//        .alert(isPresented: $showAlert) {
//            Alert(
//                title: Text("Added to your Grocery List!"),
//                message: Text(alertMessage),
//                dismissButton: .default(Text("Sure"))
//            )
//        }
//    }
//}
//
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
