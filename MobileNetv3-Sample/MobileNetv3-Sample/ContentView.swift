//
//  ContentView.swift
//  MobileNetv3-Sample
//
//  Created by Fumiya Tanaka on 2022/09/01.
//

import SwiftUI
import AVFoundation
import CoreML

struct ContentView: View {

    @State private var classLabel = ""
    @State private var currentImage: UIImage?
    @State private var showInputPreview: Bool = false
    @State private var results: [Classifier.Classification] = []

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = CGSize(
                    width: min(proxy.size.width, proxy.size.height),
                    height: min(proxy.size.width, proxy.size.height)
                )
                CameraView(size: size) { image in
                    DispatchQueue.main.async {
                        if showInputPreview {
                            currentImage = image
                        }
                    }
                    Classifier.perform(image: image, onError: { error in
                    }, onSuccess: { results in
                        self.results = results
                    })
                }
                .frame(width: size.width, height: size.height)
            }
            VStack {
                Spacer()
                List {
                    ForEach(results) { result in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Label: ")
                                Text(result.label)
                            }
                            HStack {
                                Text("Prob: ")
                                Text(String(result.prob))
                            }
                        }
                    }
                }
                .frame(height: 120)
                if let currentImage, showInputPreview {
                    Image(uiImage: currentImage)
                        .resizable()
                        .frame(width: 120, height: 120)
                }
                Toggle("Show Preview", isOn: $showInputPreview)
                    .padding()
                Spacer().frame(height: 32)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
