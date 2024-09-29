

### English Version

# Museum Exhibition Classification Project

## 📖 Project Overview
This project is a **Museum Object Classification** solution that uses **YOLO (You Only Look Once) object detection model** and an **anti-reflection model** to identify artifacts and artworks in museums and exhibition halls. It aims to enhance the accuracy of object recognition by removing reflections from images and then performing classification on the cleaned images.

Competition Website: https://aigo.org.tw/zh-tw/competitions/details/507

## ✨ Key Features
- **YOLO Object Detection**: Identifies and classifies museum objects from captured images, supporting multiple categories.
- **Anti-Reflection Model**: Improves image quality by reducing reflections, enhancing object recognition accuracy.
- **Dual Detection Result Comparison**: Compares results from the original image and the reflection-removed image, selecting the best classification.

## ⚙️ System Requirements
- iOS 14 or later
- Xcode 12.0 or later
- TensorFlow Lite

## 🛠 Installation Steps
1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/museum-exhibition-classification.git
   cd museum-exhibition-classification
   ```
2. **Open Project**
   - Open Xcode and select `museum_classification.xcodeproj`.

3. **Install Dependencies**
   - Ensure TensorFlow Lite is installed. You can use CocoaPods or manually import it into your project.

4. **Add Model Files**
   - Place the `epoch300_float32.tflite` and `aigo_model_v1.tflite` model files in the `Resources` directory of the project.

## 🚀 Usage
1. **Open Camera**: Click on the "Open Camera" button to capture an image.
2. **Process Photo**: Click on the "Process Photo" button to execute both YOLO detection and anti-reflection processes. The app will display the best classification result once completed.
3. **Save Image**: The reflection-removed image will automatically be saved to your photo library.

## 📂 Project Structure
```bash
museum_classification/
├── CameraViewModel.swift       # Core logic for camera functionality and model inference
├── ContentView.swift           # SwiftUI design for the user interface
├── ImagePicker.swift           # Image capture logic
├── Resources/                  # TensorFlow Lite model files
└── README.md                   # Project documentation
```

## 💡 Future Improvements
- **Performance Optimization**: Improve the accuracy and speed of both the anti-reflection and object classification models.
- **Multi-Language Support**: Provide localized versions for users from different regions.
- **Expanded Applications**: Adapt the model for other object recognition scenarios such as libraries, art exhibitions, etc.

## 🤝 Contribution
We welcome **Issues** and **Pull Requests**! Here's how you can contribute:
1. Fork this repository.
2. Create a feature branch (`git checkout -b feature/YourFeature`).
3. Commit your changes (`git commit -m 'Add YourFeature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a Pull Request.

## 📧 Contact
If you have any questions or suggestions about this project, feel free to reach out at: [vicky46586038@gmail.com](mailto:vicky46586038@gmail.com).

---

---

### 中文版本

# 博物館展覽物件分類項目

## 📖 項目概述
本項目是一個**博物館物件分類**解決方案，使用 **YOLO 物件檢測模型** 和 **消反光模型** 來識別博物館和展覽館中的文物和藝術品。該項目旨在通過消除圖像中的反光來提高物件識別的準確性，並對處理後的圖像進行分類。

競賽網站: https://aigo.org.tw/zh-tw/competitions/details/507

## ✨ 主要特點
- **YOLO 物件檢測**：從拍攝的圖像中識別並分類博物館物件，支持多種類別。
- **消反光模型**：通過降低反光來改善圖像質量，提高物件識別的準確性。
- **雙重檢測結果比較**：比較原始圖像和消除反光後的圖像結果，選擇最佳分類。

## ⚙️ 系統需求
- iOS 14 或更高版本
- Xcode 12.0 或更高版本
- TensorFlow Lite

## 🛠 安裝步驟
1. **克隆儲存庫**
   ```bash
   git clone https://github.com/yourusername/museum-exhibition-classification.git
   cd museum-exhibition-classification
   ```
2. **打開專案**
   - 打開 Xcode 並選擇 `museum_classification.xcodeproj`。

3. **安裝依賴項**
   - 確保已安裝 TensorFlow Lite。您可以使用 CocoaPods 或手動導入到您的專案中。

4. **添加模型文件**
   - 將 `epoch300_float32.tflite` 和 `aigo_model_v1.tflite` 模型文件放入專案的 `Resources` 目錄中。

## 🚀 使用方式
1. **開啟相機**：按下 "Open Camera" 按鈕來捕捉圖像。
2. **處理相片**：按下 "Process Photo" 按鈕來執行 YOLO 檢測和消反光處理。處理完成後，應用程式會顯示最佳分類結果。
3. **保存圖像**：消除反光後的圖像將自動保存到您的相冊。

## 📂 專案結構
```bash
museum_classification/
├── CameraViewModel.swift       # 相機功能和模型推理的核心邏輯
├── ContentView.swift           # 用於用戶界面的 SwiftUI 設計
├── ImagePicker.swift           # 圖像捕捉邏輯
├── Resources/                  # TensorFlow Lite 模型文件
└── README.md                   # 專案文件
```

## 💡 未來改進
- **性能優化**：改進消反光和物件分類模型的準確性和速度。
- **多語言支持**：提供不同地區用戶的本地化版本。
- **擴展應用**：將模型應用於其他物件識別場景，例如圖書館、藝術展覽等。

## 🤝 貢獻
我們歡迎 **問題回報** 和 **Pull Requests**！以下是貢獻的方法：

1. **Fork 本儲存庫**。
2. **建立一個功能分支** (`git checkout -b feature/YourFeature`)。
3. **提交您的更改** (`git commit -m 'Add YourFeature'`)。
4. **推送到分支** (`git push origin feature/YourFeature`)。
5. **開啟 Pull Request**。

## 📧 聯絡方式
如果您對本項目有任何疑問或建議，請隨時聯繫我們：[vicky46586038@gmail.com](mailto:vicky46586038@gmail.com)。

