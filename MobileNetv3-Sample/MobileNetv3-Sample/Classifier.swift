//
//  Classifier.swift
//  MobileNetv3-Sample
//
//  Created by Fumiya Tanaka on 2022/09/03.
//

import Foundation
import Vision
import CoreML
import UIKit

class Classifier {

    struct Classification: Identifiable {
        let label: String
        let prob: Double

        var id: String {
            label
        }

        init(label: String, prob: Double) {
            self.label = label
            self.prob = prob
        }
    }

    static func perform(image: UIImage, onError: @escaping (Error) -> Void, onSuccess: @escaping ([Classification])  -> Void) {
        guard let modelURL = Bundle.main.url(forResource: "mobilenetv3", withExtension: "mlmodelc") else {
            fatalError("Failed to load the Core ML model.")
        }
        do {
            let mlmodel = try MLModel(contentsOf: modelURL)
            

            let coremlModel = try VNCoreMLModel(for: mlmodel)
            let request = VNCoreMLRequest(model: coremlModel) { request, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
                    fatalError("Unexpected result type from VNCoreMLRequest.")
                }
                var ans: [Classification] = []

                for result in results.prefix(5) {
                    let data = result.featureValue.multiArrayValue!
                    var high: Double = 0
                    var id: Int = -1
                    for i in 0..<data.count {
                        if data[i].doubleValue > high {
                            id = i
                            high = data[i].doubleValue
                        }
                    }
                    let classification = Classification(
                        label: Self.getLabelName(id: id),
                        prob: high * 100
                    )
                    ans.append(classification)
                }
                onSuccess(ans)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: prepareImage(image)!)
            try handler.perform([request])
        } catch {
            print(error)
        }
    }

    static  func getLabelName(id: Int) -> String {
        guard let url = Bundle.main.url(forResource: "id2label", withExtension: "json") else {
            fatalError()
        }
        let data = try! Data(contentsOf: url)
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: String]
        return dict[String(id)]!
    }
}
