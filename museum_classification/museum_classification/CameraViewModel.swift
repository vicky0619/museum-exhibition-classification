import SwiftUI
import TensorFlowLite // 確保您已經添加了 TensorFlow Lite 框架
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isShowingCamera = false
    
    private var interpreter: Interpreter?
    
    init() {
        loadModel()
    }
    
    func loadModel() {
        guard let modelPath = Bundle.main.path(forResource: "aigo_model_v1", ofType: "tflite") else {
            print("無法找到.tflite文件")
            return
        }
        
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
            print("模型加載成功")
        } catch {
            print("模型加載失敗: \(error.localizedDescription)")
        }
    }
    
    func openCamera() {
        isShowingCamera = true
    }
    
    func processPhoto() {
        guard let image = capturedImage, let interpreter = interpreter else { return }
        
        // 在這裡處理照片並使用模型
        // 例如：
        // 1. 將圖片轉換為模型輸入格式
        // 2. 運行模型
        // 3. 解釋模型輸出
        // 4. 更新 UI
        
        // 示例代碼（需要根據您的具體模型進行調整）:
        /*
        do {
            let inputData = preprocess(image: image)
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let results = postprocess(outputTensor: outputTensor)
            // 使用 results 更新 UI 或進行進一步處理
        } catch {
            print("模型運行失敗: \(error.localizedDescription)")
        }
        */
    }
    
    // 添加其他必要的輔助方法，如 preprocess 和 postprocess
}
