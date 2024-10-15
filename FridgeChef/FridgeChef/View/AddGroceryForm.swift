//
//  AddGroceryForm.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct AddGroceryForm: View {
    @ObservedObject var viewModel: AddGroceryFormViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var selectedImage: UIImage?
    @State private var isSavedAlertPresented = false
    @State private var savedIngredients: [Ingredient] = []
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        
        var id: Int { self.hashValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 渐层背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
                                .padding(.bottom)
                        } else {
                            Image("RecipeFood")  // Provide a placeholder
                                .resizable()
                                .scaledToFill()  // 保持比例並完整顯示圖片
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.white.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
                                .padding(.bottom)
                                .onTapGesture {
                                    showPhotoOptions = true
                                }
                        }
                        FormTextField(label: "Name", placeholder: "Recipe Name", value: $viewModel.name)
                        FormTextField(label: "Type", placeholder: "Recipe Type", value: $viewModel.type)
                        FormTextField(label: "Notes", placeholder: "Anything to be keep in here ~", value: $viewModel.description)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
//                Button(action: saveIngredient) {
//                    Text("Save")
//                        .font(.headline)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                    
//                }
//                .padding()
//                .alert(isPresented: $isSavedAlertPresented) {
//                    Alert(title: Text("Success"), message: Text("Saved the ingredient!"), dismissButton: .default(Text("Sure")))
                }
                .navigationTitle("Add Recipe")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        .confirmationDialog("Choose your photos from", isPresented: $showPhotoOptions, titleVisibility: .visible) {
            Button("Camera") { photoSource = .camera }
            Button("Photo Library") { photoSource = .photoLibrary }
        }
        .fullScreenCover(item: $photoSource) { source in
            switch source {
            case .photoLibrary:
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary).ignoresSafeArea()
            case .camera:
                ImagePicker(image: $selectedImage, sourceType: .camera).ignoresSafeArea()
            }
        }
        .tint(.primary)
    }
//    func saveIngredient() {
//        let defaultAmount = 1.0  // 一個示例值
//        let defaultUnit = "unit" // 一個示例單位
//        
//        // 將 quantity 從 String 轉換為 Double，並四捨五入到兩位小數
//        let quantityValue = (Double(quantity) ?? 1.0).rounded(toPlaces: 2)
//        print("Converted quantity: \(quantityValue)") // 調試輸出
//        
//        // 創建 Ingredient 實例，並將 quantity 設置為 Double
//        var newIngredient = Ingredient(
//            id: editingFoodItem?.id ?? UUID(), // 如果是編輯，保持原有的 ID；否則生成新 ID
//            name: recognizedText,
//            quantity: quantityValue, // 正確設置為 Double，並已四捨五入
//            amount: defaultAmount,
//            unit: defaultUnit, // 使用實際的 unit
//            expirationDate: expirationDate, // 設置 expirationDate
//            storageMethod: storageMethod,
//            imageBase64: image?.pngData()?.base64EncodedString()
//        )
//        print("New Ingredient: \(newIngredient.quantity)")
//        savedIngredients.append(newIngredient)
//        isSavedAlertPresented = true
//        onSave?(newIngredient)
//        clearForm()
//        dismiss()
//    }
    
}

#Preview{
    AddGroceryForm(
        viewModel: AddGroceryFormViewModel()
    )
}

struct FormTextField: View {
    let label: String
    var placeholder: String = ""
    
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label.uppercased())
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color(.darkGray))
            
            TextField(placeholder, text: $value)
                .font(.system(.body, design: .rounded))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Color.white.opacity(0.3)) // 添加淡色背景
                .cornerRadius(8) // 圓角設定
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2) // 修改框線顏色和寬度
                )
                .padding(.vertical, 10)
        }
    }
}



#Preview("FormTextField", traits: .fixedLayout(width: 300, height: 200)) {
    FormTextField(label: "NAME", placeholder: "Fill in the restaurant name", value: .constant(""))
}

