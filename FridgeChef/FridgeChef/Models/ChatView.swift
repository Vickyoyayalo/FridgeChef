//
//  ChatView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/22.
//

import SwiftUI
import Foundation

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let imageData: Data?  // Optional, used if the message is a photo

    init(content: String, isFromUser: Bool, imageData: Data? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.imageData = imageData
    }
}


import SwiftUI
import PhotosUI  // For photo library access

struct ChatView: View {
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var image: UIImage?
    @State private var showChangePhotoDialog = false
    
    init(messages: [Message] = []) {
        _messages = State(initialValue: messages)
    }
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        var id: Int { self.hashValue }
    }
    
    var body: some View {
        VStack {
            Image("LogoFridgeChef")
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 80)
                .padding(.top, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) { // 可以在这里调整间距
                    ForEach(messages) { message in
                        messageView(for: message)
                            .padding(.horizontal, 10) // 为每个消息添加水平边距
                    }
                }
            }
            .padding(.top, 10) // ScrollView 顶部的边距
            
            // Image Preview Area with interactive options
            if let image = image {
                Button(action: {
                    showChangePhotoDialog = true
                }) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                        .padding(.horizontal, 10) // 图片的水平边距
                        .padding(.vertical, 5)
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
                        .font(.title)
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.leading)
                .padding(.bottom , 30)
                .confirmationDialog("選擇你的相片來源", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                    Button("相機") { photoSource = .camera }
                    Button("相冊") { photoSource = .photoLibrary }
                }
                
                TextField("今天想來點 🥙🍍 ...", text: $inputText)
                    .padding(.horizontal)
                    .padding(5)
                    .background(Color.white)  // 背景色
                    .cornerRadius(10)  // 圆角
                    .shadow(radius: 3) 
                    .padding(.bottom , 30)// 阴影
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
                .padding(.trailing)
                .padding(.bottom , 30)
            }
            .padding(.horizontal, 10) // 底部输入区的水平边距
        }
            .fullScreenCover(item: $photoSource) { source in
                ImagePicker(image: $image, sourceType: source == .photoLibrary ? .photoLibrary : .camera)
                    .ignoresSafeArea()
            }
    }

    private func messageView(for message: Message) -> some View {
        HStack {
            if message.isFromUser {
                Spacer() // 把内容推到右边
                VStack(alignment: .trailing) {
                    if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .cornerRadius(15)
                            .clipped()
                    } else {
                        Text(message.content)
                            .padding()
                            .background(Color.customColor(named: "NavigationBarTitle"))
                            .foregroundColor(.white) // 文本颜色
                            .cornerRadius(10)
                            .frame(minWidth: 100)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .cornerRadius(15)
                            .clipped()
                    } else {
                        Text(message.content)
                            .padding() // 内边距
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .frame(minWidth: 100)
                    }
                }
                Spacer() // 把内容推到左边
            }
        }
        .padding(.horizontal) // 水平边距
    }
    
    func sendMessage() {
       
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.5) {
            let newMessage = Message(content: "📷 Photo", isFromUser: true, imageData: imageData)
            messages.append(newMessage)
            self.image = nil
        }
        
       
        if !inputText.isEmpty {
            let newMessage = Message(content: inputText, isFromUser: true)
            messages.append(newMessage)
            inputText = "" 
        }
    }
}

extension Color {
    static func customColor(named name: String) -> Color {
        return Color(UIColor(named: name) ?? .systemRed) //
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(messages: [Message(content: "Hello, this is a test message.", isFromUser: false)])
    }
}
