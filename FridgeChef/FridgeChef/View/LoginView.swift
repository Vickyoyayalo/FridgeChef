//
//  LoginView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct LoginView: View {
    @State private var scaleEffect1: CGFloat = 0.5
    @State private var opacityEffect1 = 0.0
    
    @State private var scaleEffect2: CGFloat = 0.5
    @State private var opacityEffect2 = 0.0
    
    @State private var offsetEffect3: CGFloat = 200
    @State private var scaleEffect3: CGFloat = 0.8
    @State private var opacityEffect3 = 0.0

    var body: some View {
        CustomNavigationBarView(title: "Welcome") {
            ZStack(alignment: .bottom) {
                GeometryReader { geometry in
                    ZStack {
                        // 左上角的圖片
                        Image("himonster")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .shadow(radius: 10)
                            .scaleEffect(scaleEffect1)
                            .opacity(opacityEffect1)
                            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.2) // 左上角位置
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5)) {
                                    scaleEffect1 = 1.0
                                    opacityEffect1 = 1.0
                                }
                            }
                        
                        // 中間的圖片
                        Image("Launchmonster")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 1000)
                            .shadow(radius: 10)
                            .scaleEffect(scaleEffect2)
                            .opacity(opacityEffect2)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 視圖中心位置
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                                    scaleEffect2 = 1.0
                                    opacityEffect2 = 1.0
                                }
                            }
                        
                        // 右下角的圖片，從下往上進場
                        Image("discomonster")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 400)
                            .shadow(radius: 10)
                            .scaleEffect(scaleEffect3)
                            .opacity(opacityEffect3)
                            .offset(y: offsetEffect3) // 控制從下往上的動畫
                            .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.8) // 右下角位置
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5)) {
                                    offsetEffect3 = 0 // 位移動畫從下往上
                                    scaleEffect3 = 1.0
                                    opacityEffect3 = 1.0
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 父視圖撐滿
                }
                
                VStack {
                    Spacer()
                    Button("Sign In") {
                        // 按鈕邏輯
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.8)
                    )
                    .cornerRadius(25)
                    .shadow(radius: 25)
                    .padding(.horizontal)
                    
                    Button("Sign Up") {
                        // 按鈕邏輯
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)
                    )
                    .cornerRadius(25)
                    .shadow(radius: 25)
                    .padding(.horizontal)
                }
            }
        }
    }
//    
//    // 隨機生成位置，避開底部的按鈕區域
//    private func randomPosition(in size: CGSize) -> CGPoint {
//        let minX: CGFloat = 50
//        let maxX: CGFloat = size.width - 50
//        let minY: CGFloat = 100
//        let maxY: CGFloat = size.height * 0.6 // 防止圖片出現在按鈕區域
//        
//        let randomX = CGFloat.random(in: minX...maxX)
//        let randomY = CGFloat.random(in: minY...maxY)
//        
//        return CGPoint(x: randomX, y: randomY)
//    }
}


//
//// 背景影片播放部分保持不變
//struct VideoPlayerView: UIViewRepresentable {
//    var videoName: String
//    
//    func makeUIView(context: Context) -> UIView {
//        return LoopingPlayerUIView(videoName: videoName)
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {}
//}
//
//class LoopingPlayerUIView: UIView {
//    private var playerLayer = AVPlayerLayer()
//    
//    init(videoName: String) {
//        super.init(frame: .zero)
//        let player = AVPlayer(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)
//        player.isMuted = true
//        player.actionAtItemEnd = .none
//        player.play()
//        
//        playerLayer.player = player
//        playerLayer.videoGravity = .resizeAspectFill
//        layer.addSublayer(playerLayer)
//        
//        NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: player.currentItem,
//            queue: .main) { _ in
//                player.seek(to: .zero)
//                player.play()
//            }
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        playerLayer.frame = bounds
//    }
//}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .previewDevice("iPhone 15") // 指定設備，例如 "iPhone 14"
            .previewDisplayName("Login View Preview") // 預覽標題
    }
}


//import SwiftUI
//import AVKit
//
//struct LoginView: View {
//    @State private var isShowingLoginDetail = false
//    @State private var isShowingSignUp = false
//    
//    var body: some View {
//        CustomNavigationBarView(title: "Welcome") {
//            ZStack(alignment: .bottom) {
////                GeometryReader {
////                    let size = $0.size
////                    Image(.loginView)
////                        .resizable()
////                        .aspectRatio(contentMode: .fill)
////                        .offset(y: -60)
////                        .frame(width: size.width, height: size.height)
////                }
////                 背景影片
//                VideoPlayerView(videoName: "LoginVideo")
//                    .ignoresSafeArea()
//            
//                    .mask {
//                        Rectangle()
//                            .fill(.linearGradient(
//                                colors:[
//                                    .white,
//                                    .white,
//                                    .white,
//                                    .white,
//                                    .white,
//                                    .white.opacity(0.6),
//                                    .white.opacity(0.2),
//                                    .clear
//                                ],
//                                startPoint: .top,
//                                endPoint: .bottom
//                            ))
//                    }
//                    .ignoresSafeArea()
//                
//                VStack {
//                    
//                    Spacer()
//                    
//                    Button("Sign In") {
//                        self.isShowingLoginDetail = true
//                    }
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                        .opacity(0.8)  // 应用50%透明度到整个LinearGradient
//                    )
//                    .cornerRadius(25)
//                    .shadow(radius: 25)
//                    .padding(.horizontal)
//                    
//                    // 注册按钮
//                    Button("Sign Up") {
//                        self.isShowingSignUp = true
//                    }
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(
//                        Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                    .cornerRadius(25)
//                    .shadow(radius: 25)
//                    .padding(.horizontal)
//                    
//                    //                    Spacer()
//                }
//            }
//            .sheet(isPresented: $isShowingLoginDetail) {
//                LoginDetailView()
//            }
//            .sheet(isPresented: $isShowingSignUp) {
//                SignUpView()
//            }
//        }
//    }
//}
//
//// 背景影片播放
//struct VideoPlayerView: UIViewRepresentable {
//    var videoName: String
//    
//    func makeUIView(context: Context) -> UIView {
//        return LoopingPlayerUIView(videoName: videoName)
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        
//    }
//}
//
//class LoopingPlayerUIView: UIView {
//    private var playerLayer = AVPlayerLayer()
//    
//    init(videoName: String) {
//        super.init(frame: .zero)
//        let player = AVPlayer(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)
//        player.isMuted = true
//        player.actionAtItemEnd = .none
//        player.play()
//        
//        playerLayer.player = player
//        playerLayer.videoGravity = .resizeAspectFill
//        layer.addSublayer(playerLayer)
//        
//        NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: player.currentItem,
//            queue: .main) { _ in
//                player.seek(to: .zero)
//                player.play()
//            }
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        playerLayer.frame = bounds
//    }
//}
