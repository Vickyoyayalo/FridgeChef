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
                            Image("RecipeFood")
                                .resizable()
                                .scaledToFill()
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
                .background(Color.white.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2)
                )
                .padding(.vertical, 10)
        }
    }
}



#Preview("FormTextField", traits: .fixedLayout(width: 300, height: 200)) {
    FormTextField(label: "NAME", placeholder: "Fill in the restaurant name", value: .constant(""))
}

