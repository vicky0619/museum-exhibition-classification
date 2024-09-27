import SwiftUI
import AVFoundation
import TensorFlowLite
import Vision

class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isShowingCamera = false
    @Published var errorMessage: String?
    
    private var interpreter: Interpreter?
    private let captureSession = AVCaptureSession()
    
    init() {
        loadModel()
        setupCamera()
    }
    
    // 設定相機
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    func setupCamera() {
        // 建立 AVCaptureDeviceDiscoverySession 來找出可用的相機
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back // 使用後置相機
        )
        
        // 獲取第一個可用的相機裝置
        guard let camera = discoverySession.devices.first else {
            print("無法找到合適的相機裝置。")
            errorMessage = "無法找到相機裝置"
            return
        }
        
        // 迭代可用的格式並找到合適的格式
        let preferredResolution = CGSize(width: 1280, height: 720) // 根據你的需求調整解析度
        let chosenFormat = camera.formats.filter { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width >= Int32(preferredResolution.width) && dimensions.height >= Int32(preferredResolution.height)
        }.first ?? camera.formats.first

        if let format = chosenFormat {
            do {
                try camera.lockForConfiguration()
                camera.activeFormat = format // 將格式設置為活躍格式
                camera.unlockForConfiguration()
            } catch {
                print("無法配置相機：\(error.localizedDescription)")
                errorMessage = "相機配置失敗：\(error.localizedDescription)"
            }
        }
        
        // 創建相機輸入
        do {
            let deviceInput = try AVCaptureDeviceInput(device: camera)
            
            // 將輸入添加到 capture session
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
            
            // 啟動 capture session
            captureSession.startRunning()
            
        } catch {
            print("創建 AVCaptureDeviceInput 時出錯：\(error.localizedDescription)")
            errorMessage = "相機輸入創建失敗：\(error.localizedDescription)"
        }
    }
    
    // 返回相機預覽層
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    // 加載模型
    func loadModel() {
        guard let modelPath = Bundle.main.path(forResource: "aigo_model_v1", ofType: "tflite") else {
            self.errorMessage = "無法找到 .tflite 文件"
            return
        }
        
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
            print("模型加載成功")
        } catch {
            self.errorMessage = "加載模型失敗：\(error.localizedDescription)"
        }
    }
    
    // 開啟相機
    func openCamera() {
        print("Checking camera permissions...")
        checkCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("Camera permission granted.")
                    self?.isShowingCamera = true
                } else {
                    print("Camera permission denied.")
                    self?.errorMessage = "需要相機權限才能使用此功能。"
                }
            }
        }
    }

    // 檢查相機權限
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera is already authorized.")
            completion(true)
        case .notDetermined:
            print("Camera permission not determined, requesting access...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("User response to camera permission: \(granted ? "Granted" : "Denied")")
                completion(granted)
            }
        case .denied, .restricted:
            print("Camera access denied or restricted.")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "相機權限被拒絕。請在設置中允許訪問相機。"
            }
            completion(false)
        @unknown default:
            print("Unknown camera permission status.")
            completion(false)
        }
    }

    // 處理相片
    func processPhoto() {
        guard let image = capturedImage else {
            self.errorMessage = "沒有擷取到圖像"
            return
        }
        guard let interpreter = interpreter else {
            self.errorMessage = "解釋器未初始化"
            return
        }
        
        // 確保圖像大小符合模型要求
        let modelInputSize = CGSize(width: 256, height: 256) // 模型要求 256x256
        
        // 調整圖片到模型輸入尺寸
        guard let resizedImage = image.resize(to: modelInputSize) else {
            self.errorMessage = "圖像調整大小失敗"
            return
        }
        
        // 確保圖像數據格式為 RGB
        guard let rgbData = resizedImage.rgbData else {
            self.errorMessage = "圖像預處理失敗"
            return
        }
        
        // 確保數據大小正確
        let expectedByteCount = 256 * 256 * 3 // 模型要求的字節數：256 x 256 x 3 (RGB)
        if rgbData.count != expectedByteCount {
            self.errorMessage = "預處理後的圖像數據大小不正確。期望：\(expectedByteCount)，實際：\(rgbData.count)"
            return
        }
        
        // 將 UInt8 數據轉換為 Float32 並歸一化到 [0, 1]
        let floatData = rgbData.map { Float32($0) / 255.0 }
        
        // 確認 floatData 大小與模型的輸入張量大小匹配
        let expectedInputSize = try? interpreter.input(at: 0).shape.dimensions.reduce(1, *)
        if floatData.count != expectedInputSize {
            self.errorMessage = "輸入數據大小與模型預期不匹配。期望：\(expectedInputSize ?? 0)，實際：\(floatData.count)"
            return
        }
        
        // 設置輸入張量
        floatData.withUnsafeBufferPointer { bufferPointer in
            do {
                try interpreter.copy(Data(buffer: bufferPointer), toInputAt: 0)
            } catch {
                self.errorMessage = "設置輸入張量失敗：\(error.localizedDescription)"
                return
            }
        }
        
        // 執行推論
        do {
            try interpreter.invoke()
        } catch {
            self.errorMessage = "執行推論失敗：\(error.localizedDescription)"
            return
        }
        
        // 獲取輸出並轉換為圖片
        guard let outputTensor = try? interpreter.output(at: 0) else {
            self.errorMessage = "獲取輸出張量失敗"
            return
        }
        
        let outputData = outputTensor.data.toArray(type: Float32.self)
        let outputShape = outputTensor.shape.dimensions
        let height = outputShape[1]
        let width = outputShape[2]
        
        if let outputImage = convertToUIImage(outputData: outputData, width: width, height: height) {
            saveImageToPhotos(outputImage)
        } else {
            self.errorMessage = "無法轉換模型輸出為圖片"
        }
    }


    
    // 將模型輸出的數據轉換為 UIImage
    func convertToUIImage(outputData: [Float32], width: Int, height: Int) -> UIImage? {
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let r = UInt8(min(max((outputData[index * 3] + 1) * 127.5, 0), 255))
                let g = UInt8(min(max((outputData[index * 3 + 1] + 1) * 127.5, 0), 255))
                let b = UInt8(min(max((outputData[index * 3 + 2] + 1) * 127.5, 0), 255))
                
                pixelData[(y * width + x) * bytesPerPixel] = r
                pixelData[(y * width + x) * bytesPerPixel + 1] = g
                pixelData[(y * width + x) * bytesPerPixel + 2] = b
                pixelData[(y * width + x) * bytesPerPixel + 3] = 255 // Alpha 通道設為不透明
            }
        }
        
        guard let providerRef = CGDataProvider(data: Data(pixelData) as CFData) else { return nil }
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bytesPerPixel * bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // 保存圖片到相冊
    func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    var rgbData: Data? {
        guard let cgImage = self.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4 // 使用 4 bytes per pixel 以保持對齊
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        // 使用適當大小的數組來儲存 RGBA 數據
        var rawBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        // 創建一個 RGBA 格式的 CGContext
        rawBytes.withUnsafeMutableBytes { ptr in
            if let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) {
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                context.draw(cgImage, in: rect)
            }
        }
        
        // 返回純 RGB 數據（剔除 Alpha 通道）
        var rgbBytes = [UInt8]()
        for i in stride(from: 0, to: rawBytes.count, by: bytesPerPixel) {
            rgbBytes.append(rawBytes[i])     // R
            rgbBytes.append(rawBytes[i + 1]) // G
            rgbBytes.append(rawBytes[i + 2]) // B
            // 忽略 Alpha 通道（rawBytes[i + 3]）
        }
        
        return Data(rgbBytes)
    }
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = [T](repeating: 0, count: self.count / MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { self.copyBytes(to: $0) }
        return array
    }
}
