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

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CameraView(size: proxy.size) { image in                    
                    Classifier.perform(image: image, onError: { error in
                    }, onSuccess: { results in
                        classLabel = ""
                        for result in results {
                            if !classLabel.isEmpty {
                                classLabel = "\n"
                            }
                            classLabel += "Label: \(result.label). Confidence: \(result.prob)."
                        }
                    })
                }
                VStack {
                    Spacer()
                    Text(classLabel)
                        .background(Color.white)
                        .padding()
                    Spacer().frame(height: 32)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
