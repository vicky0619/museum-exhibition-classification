//
//  ContentView.swift
//  museum_classification
//
//  Created by Vicky T on 9/1/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        VStack {
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("No image captured")
            }
            
            HStack {
                Button("Open Camera") {
                    viewModel.openCamera()
                }
                
                Button("Process Photo") {
                    viewModel.processPhoto()
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCamera) {
            ImagePicker(image: $viewModel.capturedImage, sourceType: .camera)
        }
    }
}
