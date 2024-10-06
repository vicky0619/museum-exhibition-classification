import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "#20484b")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 添加博物館 Logo
                if let logoImage = UIImage(named: "museum_logo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100) // 根據需要調整 Logo 的高度
                        .padding()
                }
                
                // 相機預覽
                if viewModel.isShowingCamera {
                    CameraPreview(previewLayer: viewModel.getPreviewLayer())
                        .frame(height: 400)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .padding()
                }
                
                // 擷取到的圖像
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300) // 增大圖片預覽大小
                        .cornerRadius(10)
                        .padding()
                        .shadow(radius: 5)
                } else {
                    Text("尚未擷取圖像")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // 最終結果
                if !viewModel.finalResult.isEmpty {
                    Text("\(viewModel.finalResult)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#91bec5"))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                // 按鈕區域
                HStack {
                    CustomButton(title: "打開相機") {
                        viewModel.openCamera()
                    }
                    
                    CustomButton(title: "處理相片") {
                        viewModel.getFinalResult()
                    }
                }
                .padding()
                
                // 錯誤信息
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    
                    if errorMessage.contains("相機權限被拒絕") {
                        Button("打開設置") {
                            viewModel.openSettings()
                        }
                        .font(.headline)
                        .foregroundColor(Color(hex: "#91bec5"))
                    }
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.setupCamera()
            viewModel.loadModels()
        }
        .sheet(isPresented: $viewModel.isShowingCamera) {
            ImagePicker(image: $viewModel.capturedImage, sourceType: .camera)
        }
    }
}

// 自定義按鈕
struct CustomButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding()
                .foregroundColor(Color(hex: "#20484b")) // 按鈕文字顏色
                .background(Color(hex: "#91bec5")) // 按鈕背景顏色
                .cornerRadius(10)
                .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}

// CameraPreview 用於顯示 AVCaptureVideoPreviewLayer
struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

// 顏色擴展以支持 HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = scanner.string.index(after: scanner.string.startIndex)
        }
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
