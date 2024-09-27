import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack {
            // 顯示相機預覽
            if viewModel.isShowingCamera {
                CameraPreview(previewLayer: viewModel.getPreviewLayer())
                    .edgesIgnoringSafeArea(.all)
                    .frame(height: 400) // 根據需要調整預覽高度
            }
            
            // 顯示擷取到的圖像
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Text("尚未擷取圖像")
            }
            
            // 操作按鈕
            HStack {
                Button("打開相機") {
                    viewModel.openCamera()
                }
                
                Button("處理相片") {
                    viewModel.processPhoto()
                }
            }
            .padding()

            // 顯示錯誤信息
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                
                if errorMessage.contains("相機權限被拒絕") {
                    Button("打開設置") {
                        viewModel.openSettings() // 確保這裡正確調用
                    }
                }
            }
        }
        .onAppear {
            viewModel.setupCamera() // 初始化相機
        }
        .sheet(isPresented: $viewModel.isShowingCamera) {
            ImagePicker(image: $viewModel.capturedImage, sourceType: .camera) // 保留你的 ImagePicker
        }
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
