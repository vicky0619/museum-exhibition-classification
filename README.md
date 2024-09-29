---

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

