//
//  LoginDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//
import SwiftUI
import AuthenticationServices
import Firebase
import CryptoKit
import FirebaseAuth

struct LoginDetailView: View {
    @StateObject private var loginViewModel = LoginDetailViewModel()
    @StateObject private var userViewModel = UserViewModel() 
    @State private var navigateToHome = false
    @State private var navigateToForgotPassword = false
    @State private var isLoggedIn = false
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var nonce: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        CustomNavigationBarView(title: "") {
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 15) {
                    Image("LogoFridgeChef")
                        .resizable()
                        .scaledToFit()
                        .padding(.vertical, -50)
                        .padding(.top, -25)
                    
                    // Email TextField
                    TextField("Email", text: $loginViewModel.email)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    // Password SecureField
                    SecureField("Password", text: $loginViewModel.password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 5) // 增加陰影效果
                    
                    // 登入按鈕
                    Button(action: {
                        navigateToHome = true
                    }) {
                        Text("登入")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $navigateToHome) {
                        MainTabView()
                    }
                    
                    
                    // 忘記密碼按鈕
                    Button(action: {
                        print("忘記密碼按钮被點擊")
                        navigateToForgotPassword = true
                    }) {
                        Text("忘記密碼?")
                            .foregroundColor(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                                Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange), lineWidth: 2))
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $navigateToForgotPassword) {
                        ForgotPasswordView()
                    }
                    
                    // 分隔线
                    Text("Or sign up with")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    // Sign In Button
                    VStack(alignment: .leading) {
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonceString()
                            self.nonce = nonce
                            //Yout Preference
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization) :
                                loginWithFirebase(authorization)                            case .failure(let error):
                                showError(error.localizedDescription)
                            }
                        }
                        .overlay {
                            ZStack {
                                Capsule()
                                
                                HStack {
                                    Image(systemName: "applelogo")
                                    
                                    Text("Sign in with Apple")
                                }
                                .foregroundStyle(scheme == .dark ? .black : .white)
                            }
                            .allowsHitTesting(false)
                        }
                        .frame(height: 45)
                        .clipShape(.capsule)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
                    
                }
                .padding()
                Image("monster")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 300)
                    .offset(x: -50, y: 250)
            }
        }
        .alert(errorMessage, isPresented: $showAlert) {}
        .overlay {
            if isLoggedIn {
                LoadingScreen()
            }
        }
        .alert(isPresented: $loginViewModel.showAlert) {
            Alert(title: Text("Error"), message: Text(loginViewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    @ViewBuilder
    func LoadingScreen() -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            
            ProgressView()
                .frame(width: 45, height: 45)
                .background(.background, in: .rect(cornerRadius: 5))
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showAlert.toggle()
        isLoggedIn = false
    }
    
    func loginWithFirebase(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            isLoggedIn = true
            
            guard let nonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                showError("Cannot process your request.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                showError("Cannot process your request.")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                showError("Cannot process your request.")
                return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    showError(error.localizedDescription)
                }
                // User is signed in to Firebase with Apple.
                // Pushing User to MainTabView
                logStatus = true
                isLoggedIn = false
            }
        }
    }
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    LoginDetailView()
}
