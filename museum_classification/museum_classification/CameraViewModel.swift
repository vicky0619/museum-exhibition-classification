import SwiftUI
import AVFoundation
import TensorFlowLite

class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isShowingCamera = false
    @Published var finalResult: String = "" // 用來顯示最終結果
    @Published var detectedArtifacts: [String] = [] // 用來儲存偵測到的文物
    @Published var errorMessage: String?

    private var yoloInterpreter: Interpreter?
    private var antiReflectionInterpreter: Interpreter?
    private let captureSession = AVCaptureSession()
    
    init() {
        loadModels()
        setupCamera()
    }

    // 保存圖片到相冊
    func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    // 加載 YOLO 和消反光模型
    func loadModels() {
        // 加載 YOLO 模型
        if let yoloPath = Bundle.main.path(forResource: "no_reflex2000_float32", ofType: "tflite") {
            do {
                yoloInterpreter = try Interpreter(modelPath: yoloPath)
                try yoloInterpreter?.allocateTensors()
                print("YOLO 模型加載成功")
                // 確認 YOLO 模型輸入輸出尺寸
                if let yoloInterpreter = yoloInterpreter {
                    let inputShape = try yoloInterpreter.input(at: 0).shape.dimensions
                    let outputShape = try yoloInterpreter.output(at: 0).shape.dimensions
                    print("YOLO 模型輸入尺寸：\(inputShape)")
                    print("YOLO 模型輸出尺寸：\(outputShape)")
                }
            } catch {
                errorMessage = "YOLO 模型加載失敗：\(error.localizedDescription)"
            }
        } else {
            errorMessage = "無法找到 YOLO 模型文件"
        }
        
        // 加載消反光模型
        if let antiReflectionPath = Bundle.main.path(forResource: "aigo_model_v1", ofType: "tflite") {
            do {
                antiReflectionInterpreter = try Interpreter(modelPath: antiReflectionPath)
                try antiReflectionInterpreter?.allocateTensors()
                print("消反光模型加載成功")
                // 確認消反光模型輸入輸出尺寸
                if let antiReflectionInterpreter = antiReflectionInterpreter {
                    let inputShape = try antiReflectionInterpreter.input(at: 0).shape.dimensions
                    let outputShape = try antiReflectionInterpreter.output(at: 0).shape.dimensions
                    print("消反光模型輸入尺寸：\(inputShape)")
                    print("消反光模型輸出尺寸：\(outputShape)")
                }
            } catch {
                errorMessage = "消反光模型加載失敗：\(error.localizedDescription)"
            }
        } else {
            errorMessage = "無法找到消反光模型文件"
        }
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
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            
        } catch {
            print("創建 AVCaptureDeviceInput 時出錯：\(error.localizedDescription)")
            errorMessage = "相機輸入創建失敗：\(error.localizedDescription)"
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
    private var outputData: [Float32] = [] // 初始化為空
    // 處理 YOLO 模型推理
    func processYolo() -> [(String, Float)]? {
        outputData = []
        guard let image = capturedImage else {
            errorMessage = "沒有擷取到圖像"
            return nil
        }
        guard let yoloInterpreter = yoloInterpreter else {
            errorMessage = "YOLO 解釋器未初始化"
            return nil
        }

        guard let inputTensorData = prepareImageForModel(image: image, size: CGSize(width: 640, height: 640)) else {
            errorMessage = "圖像預處理失敗"
            return nil
        }
        
        do {
            try yoloInterpreter.copy(inputTensorData, toInputAt: 0)
            try yoloInterpreter.invoke()
            
            // Get parsed results
            let results = parseYoloOutput(from: yoloInterpreter)
            
            // Log all detected results
            results.forEach { result in
                print("檢測到的類別：\(result.0)，機率：\(result.1)")
            }
            
            return results
            
        } catch {
            errorMessage = "YOLO 推理失敗：\(error.localizedDescription)"
            return nil
        }
    }


    
    // 處理消反光 -> YOLO 模型推理
    func processAntiReflectionYolo() -> [(String, Float)]? {
        // 初始化 outputData
        outputData = []
        guard let image = capturedImage else {
            errorMessage = "沒有擷取到圖像"
            return nil
        }

        guard let antiReflectionInterpreter = antiReflectionInterpreter else {
            errorMessage = "消反光解釋器未初始化"
            return nil
        }
        
        guard let yoloInterpreter = yoloInterpreter else {
            errorMessage = "YOLO 解釋器未初始化"
            return nil
        }
        
        do {
            // 預處理圖片
            print("開始預處理圖片")
            guard let inputTensorData = prepareImageForModel(image: image, size: CGSize(width: 256, height: 256)) else {
                errorMessage = "圖像預處理失敗"
                return nil
            }
            print("預處理圖片完成，數據長度：", inputTensorData.count)

            // 消反光模型推理
            try antiReflectionInterpreter.copy(inputTensorData, toInputAt: 0)
            try antiReflectionInterpreter.invoke()
            print("消反光模型推理完成")
            
            // 獲取消反光模型的輸出並轉換為 UIImage
            guard let processedImage = getProcessedImageFromAntiReflectionModel(from: antiReflectionInterpreter) else {
                errorMessage = "無法轉換消反光模型輸出為圖片"
                return nil
            }
            // 保存消反光後的圖片到相簿
            saveImageToPhotos(processedImage)
            print("消反光後的圖片已保存到相簿")
            // 預處理消反光後的圖片
            guard let processedTensorData = prepareImageForModel(image: processedImage, size: CGSize(width: 640, height: 640)) else {
                errorMessage = "消反光後的圖像預處理失敗"
                return nil
            }
            print("消反光後的圖片預處理完成，數據長度：", processedTensorData.count)
            
            // 使用 YOLO 進行推理
            try yoloInterpreter.copy(processedTensorData, toInputAt: 0)
            try yoloInterpreter.invoke()
            print("YOLO 推理完成")
            
            // 獲取 YOLO 模型的標籤
            let output2 = parseYoloOutput(from: yoloInterpreter)
            
            if !output2.isEmpty {
                // 打印所有結果
                output2.forEach { result in
                    print("消反光後 YOLO 模型輸出：\(result.0)，機率：\(result.1)")
                }
                return output2
            } else {
                print("YOLO 模型無結果")
                return nil
            }
            
        } catch {
            errorMessage = "消反光 YOLO 推理失敗：\(error.localizedDescription)"
            return nil
        }
    }


    
    // 比較兩者輸出，取最大值
    // combined results
    func getFinalResult() {
        // Get results from the original YOLO model
        guard let yoloResults = processYolo() else {
            errorMessage = "YOLO 模型輸出為空或無效"
            return
        }
        
        // Get results from the anti-reflection YOLO model
        guard let antiReflectionResults = processAntiReflectionYolo() else {
            errorMessage = "消反光 YOLO 模型輸出為空或無效"
            return
        }
        
        print("原始 YOLO 輸出：\(yoloResults)")
        print("消反光後 YOLO 輸出：\(antiReflectionResults)")
        
        // Combine results and remove duplicates
        var combinedResults = Set(yoloResults.map { $0.0 }).union(antiReflectionResults.map { $0.0 })
        
        // If there are known artifacts in the results, remove "未知類別"
        if combinedResults.contains(where: { $0 != "未知類別" }) {
            combinedResults.remove("未知類別")
        }
        
        // Update the detected artifacts
        detectedArtifacts = Array(combinedResults)
            
        print("最終結果：\(detectedArtifacts)")
    }


    
    // 圖片預處理
    private func prepareImageForModel(image: UIImage, size: CGSize) -> Data? {
        // 調整圖像大小
        guard let resizedImage = image.resize(to: size) else {
            print("圖像縮放失敗")
            return nil
        }
        print("圖像縮放成功")

        // 獲取 RGB 數據
        guard let rgbData = resizedImage.rgbData else {
            print("圖像 RGB 數據轉換失敗")
            return nil
        }
        print("獲取 RGB 數據成功，數據長度：", rgbData.count)

        // 確保數據長度與模型預期一致
        let expectedByteCount = Int(size.width * size.height * 3) // RGB 圖片
        if rgbData.count != expectedByteCount {
            print("數據長度不匹配，預期：\(expectedByteCount)，實際：\(rgbData.count)")
            return nil
        }

        // 將 UInt8 轉換為 Float32 並歸一化到 [0, 1]
        let floatData = rgbData.map { Float32($0) / 255.0 }
        print("轉換為 Float32 並歸一化成功，數據長度：", floatData.count)

        // 將 Float32 數組轉換為 Data
        // 使用 withUnsafeBufferPointer 確保內存安全
        let data = floatData.withUnsafeBufferPointer { bufferPointer in
            return Data(buffer: bufferPointer)
        }
        return data
    }

    
    // 獲取消反光模型輸出並轉換為 UIImage
    private func getProcessedImageFromAntiReflectionModel(from interpreter: Interpreter) -> UIImage? {
        // 解析消反光模型的輸出，並轉換成 UIImage
        // 假設模型的輸出是一張圖片，並且大小與模型的輸入相同
        guard let outputTensor = try? interpreter.output(at: 0) else {
            return nil
        }
        let outputData = outputTensor.data.toArray(type: Float32.self)
        
        // 轉換為 UIImage（根據模型輸出的形狀確定圖片的大小）
        // 假設輸出的形狀為 (1, 256, 256, 3) [batch_size, height, width, channels]
        let height = 256
        let width = 256
        return convertOutputToUIImage(outputData: outputData, width: width, height: height)
    }
    
    // 將模型輸出轉換為 UIImage
    private func convertOutputToUIImage(outputData: [Float32], width: Int, height: Int) -> UIImage? {
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        // 創建空的像素數據數組
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let r = UInt8(min(max((outputData[index * 3] + 1) * 127.5, 0), 255))
                let g = UInt8(min(max((outputData[index * 3 + 1] + 1) * 127.5, 0), 255))
                let b = UInt8(min(max((outputData[index * 3 + 2] + 1) * 127.5, 0), 255))
                
                // 設置 RGBA 像素
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
    struct BoundingBox {
        let x1: Float
        let y1: Float
        let x2: Float
        let y2: Float
        let cx: Float
        let cy: Float
        let w: Float
        let h: Float
        let cnf: Float
        let cls: Int
        let clsName: String
    }
    

    // YOLO 模型的標籤 (根據你的模型更新這些標籤)
    let yoloLabels = ["obj1", "obj2", "obj3", "obj4", "obj5", "obj6", "obj7"]
    let yoloChineseLabels = ["蟠龍方壺", "虎形尊", "獸形器座", "青花花鳥八角盒", "三彩馬", "金柄銅短劍", "三彩加藍人面鎮墓獸"]
    private func parseYoloOutput(from interpreter: Interpreter) -> [(String, Float)] {
        guard let outputTensor = try? interpreter.output(at: 0) else {
            print("無法獲取 YOLO 模型的輸出張量")
            return []
        }

        let data = outputTensor.data
        let outputData = data.toArray(type: Float32.self)
        
        // Initialize a maxProbabilities array to store maximum probabilities for each class
        var maxProbabilities = [Float](repeating: -1.0, count: 11)
        
        // Iterate over bounding boxes and classes to extract probabilities
        for j in 4..<11 {
            for i in 0..<8400 {
                let probabilityIndex = 8400 * j + i
                let probability = outputData[probabilityIndex]
                if probability > maxProbabilities[j] {
                    maxProbabilities[j] = probability
                }
            }
        }
        
        // Print each maxProbability for debugging
        for (index, probability) in maxProbabilities.enumerated() {
            print("maxProbability[\(index)]: \(probability)")
        }
        
        // Set the threshold
        let threshold: Float = 0.7
        var detectedLabels: [(String, Float)] = []
        
        // Collect all labels that exceed the threshold
        for (index, probability) in maxProbabilities.enumerated() where probability > threshold {
            let yoloLabelIndex = index - 4
            if yoloLabelIndex >= 0 && yoloLabelIndex < yoloChineseLabels.count {
                let detectedLabel = yoloChineseLabels[yoloLabelIndex]
                print("檢測到的類別：\(detectedLabel)，機率：\(probability)")
                detectedLabels.append((detectedLabel, probability))
            }
        }
        
        // Return the detected labels
        return detectedLabels.isEmpty ? [("未知類別", 0)] : detectedLabels
    }




    func parseBoundingBoxes(from data: Data) -> [BoundingBox] {
        var boundingBoxes: [BoundingBox] = []

        // 定義 `Float` 和 `Int` 的大小
        let floatSize = MemoryLayout<Float>.size
        let intSize = MemoryLayout<Int>.size
        
        // 確保資料長度足夠解析一個完整的 `BoundingBox`
        let boundingBoxSize = floatSize * 9 + intSize // 每個 BoundingBox 有 9 個 Float 和 1 個 Int

        guard data.count % boundingBoxSize == 0 else {
            print("Data 長度不匹配 BoundingBox 結構")
            return boundingBoxes
        }

        // 開始解析
        for i in stride(from: 0, to: data.count, by: boundingBoxSize) {
            let x1 = data.subdata(in: i..<i + floatSize).withUnsafeBytes { $0.load(as: Float.self) }
            let y1 = data.subdata(in: i + floatSize..<i + floatSize * 2).withUnsafeBytes { $0.load(as: Float.self) }
            let x2 = data.subdata(in: i + floatSize * 2..<i + floatSize * 3).withUnsafeBytes { $0.load(as: Float.self) }
            let y2 = data.subdata(in: i + floatSize * 3..<i + floatSize * 4).withUnsafeBytes { $0.load(as: Float.self) }
            let cx = data.subdata(in: i + floatSize * 4..<i + floatSize * 5).withUnsafeBytes { $0.load(as: Float.self) }
            let cy = data.subdata(in: i + floatSize * 5..<i + floatSize * 6).withUnsafeBytes { $0.load(as: Float.self) }
            let w = data.subdata(in: i + floatSize * 6..<i + floatSize * 7).withUnsafeBytes { $0.load(as: Float.self) }
            let h = data.subdata(in: i + floatSize * 7..<i + floatSize * 8).withUnsafeBytes { $0.load(as: Float.self) }
            let cnf = data.subdata(in: i + floatSize * 8..<i + floatSize * 9).withUnsafeBytes { $0.load(as: Float.self) }
            let cls = data.subdata(in: i + floatSize * 9..<i + floatSize * 9 + intSize).withUnsafeBytes { $0.load(as: Int.self) }
            
            // 確保 cls 在 yoloLabels 的範圍內
            let clsName = cls >= 0 && cls < yoloLabels.count ? yoloLabels[cls] : "未知類別"
                    
            let boundingBox = BoundingBox(x1: x1, y1: y1, x2: x2, y2: y2, cx: cx, cy: cy, w: w, h: h, cnf: cnf, cls: cls, clsName: clsName)
            boundingBoxes.append(boundingBox)
        }

        return boundingBoxes
    }



}




// 擴展 UIImage
extension UIImage {
    // 調整圖片大小
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    // 獲取圖片的 RGB 數據
    var rgbData: Data? {
        guard let cgImage = self.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4 // RGBA 格式為 4 字節 per pixel
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        // 用於存儲 RGB 數據的數組
        var rawBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        // 使用 Core Graphics 提取圖片數據
        rawBytes.withUnsafeMutableBytes { ptr in
            if let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                context.draw(cgImage, in: rect)
            }
        }
        
        // 移除 Alpha 通道數據，僅保留 RGB
        var rgbBytes = [UInt8]()
        for i in stride(from: 0, to: rawBytes.count, by: bytesPerPixel) {
            rgbBytes.append(rawBytes[i])     // R
            rgbBytes.append(rawBytes[i + 1]) // G
            rgbBytes.append(rawBytes[i + 2]) // B
        }
        
        return Data(rgbBytes)
    }
}
// 擴展 Data 類型
extension Data {
    // 將 Data 轉換為指定類型的數組
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = [T](repeating: 0, count: self.count / MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { self.copyBytes(to: $0) }
        return array
    }
}
