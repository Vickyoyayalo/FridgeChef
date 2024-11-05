//
//  MLIngredientView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI
import PhotosUI
import Speech
import SDWebImageSwiftUI

struct MLIngredientView: View {
    @StateObject var viewModel: MLIngredientViewModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject var foodItemStore: FoodItemStore
    private let timer = Timer.publish(every: 86400, on: .main, in: .common).autoconnect()
    
    var onSave: ((Ingredient) -> Void)?
    var editingFoodItem: Ingredient?
    
    let storageOptions = ["Fridge", "Freezer"]
    
    let columns = [
        GridItem(.fixed(120), alignment: .leading),
        GridItem(.flexible())
    ]
    
    init(onSave: ((Ingredient) -> Void)? = nil, editingFoodItem: Ingredient? = nil, foodItemStore: FoodItemStore) {
        self.onSave = onSave
        self.editingFoodItem = editingFoodItem
        self.foodItemStore = foodItemStore
        _viewModel = StateObject(wrappedValue: MLIngredientViewModel(editingFoodItem: editingFoodItem, onSave: onSave))
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white
        UISegmentedControl.appearance().backgroundColor = UIColor(named: "NavigationBarTitle") ?? UIColor.orange
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 15)!], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont(name: "ArialRoundedMTBold", size: 15)!], for: .normal)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 10) {
                        if let image = viewModel.image {
                            // Display the image loaded from ViewModel
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
                                .padding(.bottom)
                                .onTapGesture {
                                    viewModel.showPhotoOptions = true
                                }
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
                                    viewModel.showPhotoOptions = true
                                }
                        }
                        
                        Picker("Choose the storage method.", selection: $viewModel.storageMethod) {
                            ForEach(storageOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .cornerRadius(8)
                        
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                            Text("Name")
                                .font(.custom("ArialRoundedMTBold", size: 18))
                            HStack {
                                TextEditor(text: $viewModel.recognizedText)
                                    .scrollContentBackground(.hidden)
                                    .padding(6)
                                    .background(Color.clear)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            .frame(height: 44)
                            
                            Text("Quantity")
                                .font(.custom("ArialRoundedMTBold", size: 18))
                            TextField("Please insert numbers", text: $viewModel.quantity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .keyboardType(.decimalPad)
                                .frame(maxWidth: .infinity)
                            
                            Text("Expiry Date")
                                .font(.custom("ArialRoundedMTBold", size: 18))
                            DatePickerTextField(date: $viewModel.expirationDate, label: "Choose a Date!")
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.saveIngredient()
                            dismiss()
                        }, label: {
                            Text("Save")
                                .font(.custom("ArialRoundedMTBold", size: 20))
                                .padding()
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        })
                        .padding()
                        .alert(isPresented: $viewModel.isSavedAlertPresented) {
                            Alert(title: Text("Success"), message: Text("Saved the ingredient!"), dismissButton: .default(Text("OK")))
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            
                            Text("👨🏽‍🍳 Summary List....")
                                .font(.custom("ArialRoundedMTBold", size: 18))
                                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("🥬 Fridge Items")
                                    .font(.headline)
                                ForEach(foodItemStore.foodItems.filter { $0.status == .fridge }) { item in
                                    HStack {
                                        Text(item.name)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("\(item.quantity, specifier: "%.2f") \(item.unit)")
                                            .font(.custom("ArialRoundedMTBold", size: 15))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 1)
                                }
                                
                                Text("⛄️ Freezer Items")
                                    .font(.headline)
                                ForEach(foodItemStore.foodItems.filter { $0.status == .freezer }) { item in
                                    HStack {
                                        Text(item.name)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("\(item.quantity, specifier: "%.2f") \(item.unit)")
                                            .font(.custom("ArialRoundedMTBold", size: 15))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 1)
                                }
                                
                                Text("🛒 Grocery Items")
                                    .font(.headline)
                                ForEach(foodItemStore.foodItems.filter { $0.status == .toBuy }) { item in
                                    HStack {
                                        Text(item.name)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("\(item.quantity, specifier: "%.2f") \(item.unit)")
                                            .font(.custom("ArialRoundedMTBold", size: 15))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 1)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(30)
                        .shadow(radius: 3)
                    }
                    
                    .padding()
                    .confirmationDialog("Choose your photos from", isPresented: $viewModel.showPhotoOptions, titleVisibility: .visible) {
                        Button("Camera") { viewModel.photoSource = .camera }
                        Button("Photo Library") { viewModel.photoSource = .photoLibrary }
                    }
                    .fullScreenCover(item: $viewModel.photoSource) { source in
                        switch source {
                        case .photoLibrary:
                            ImagePicker(image: $viewModel.image, sourceType: .photoLibrary)
                                .ignoresSafeArea()
                                .onDisappear {
                                    if let image = viewModel.image {
                                        viewModel.recognizeFood(in: image)
                                    }
                                }
                        case .camera:
                            ImagePicker(image: $viewModel.image, sourceType: .camera)
                                .ignoresSafeArea()
                                .onDisappear {
                                    if let image = viewModel.image {
                                        viewModel.recognizeFood(in: image)
                                    }
                                }
                        }
                    }
                    .onAppear {
                        viewModel.requestSpeechRecognitionAuthorization()
                    }
                }
                .scrollIndicators(.hidden)
                .navigationTitle("Add Ingredient")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss()
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        })
                    }
                }
                .alert(isPresented: $viewModel.showPhotoPermissionAlert) {
                    Alert(
                        title: Text("Allow Photo Access"),
                        message: Text("We need your permission to access the photo library so you can upload ingredient images."),
                        primaryButton: .default(Text("Allow")) {
                            viewModel.requestPhotoLibraryPermission()
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                .alert(isPresented: $viewModel.photoPermissionDenied) {
                    Alert(
                        title: Text("Cannot Access Photos"),
                        message: Text("Please go to the app settings to enable photo access permissions."),
                        primaryButton: .default(Text("Settings")) {
                            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(appSettings)
                            }
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                
                .alert(isPresented: $viewModel.showCameraPermissionAlert) {
                    Alert(
                        title: Text("Allow Camera Access"),
                        message: Text("We need your permission to access the camera so you can take photos of ingredients."),
                        primaryButton: .default(Text("Allow")) {
                            viewModel.requestCameraPermission()
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
                .alert(isPresented: $viewModel.cameraPermissionDenied) {
                    Alert(
                        title: Text("Cannot Access Camera"),
                        message: Text("Please go to the app settings to enable camera access permissions."),
                        primaryButton: .default(Text("Settings")) {
                            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(appSettings)
                            }
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
            }
        }
    }
}

struct MLIngredientView_Previews: PreviewProvider {
    static var previews: some View {
        let foodItemStore = FoodItemStore()
        let MLIngredientViewModel = MLIngredientViewModel()
        MLIngredientView(
            onSave: { ingredient in
                print("Preview Save: \(ingredient)")
            },
            editingFoodItem: nil,
            foodItemStore: foodItemStore
        )
    }
}
