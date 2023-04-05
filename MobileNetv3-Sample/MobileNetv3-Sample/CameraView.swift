//
//  CameraView.swift
//  MobileNetv3-Sample
//
//  Created by Fumiya Tanaka on 2022/09/02.
//

import Foundation
import VideoToolbox
import AVFoundation
import SwiftUI

struct CameraView: UIViewRepresentable {

    let size: CGSize
    let didReceiveFrameOutput: (UIImage) -> Void

    class UICameraView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(size: size)
    }

    func makeUIView(context: Context) -> UICameraView {
        let view = UICameraView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.frame = CGRect(origin: .zero, size: .zero)
        context.coordinator.didReceiveFrameOutput = { frame in
            DispatchQueue.main.async {
                self.didReceiveFrameOutput(frame)
            }
        }
        return view
    }

    func updateUIView(_ uiView: UICameraView, context: Context) {
    }
}

extension CameraView {
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let session: AVCaptureSession = .init()
        let size: CGSize
        let sessionQueue: DispatchQueue = .init(label: "")
        let videoOutput = AVCaptureVideoDataOutput()

        var didReceiveFrameOutput: ((UIImage) -> Void)?

        var cnt: Int = 0
        let limit: Int = 60

        init(size: CGSize) {
            self.size = size
            super.init()

            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {

                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.sessionQueue.async {
                            self.configure()
                        }
                    }
                }
            } else if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                sessionQueue.async {
                    self.configure()
                }
            }
        }

        private func configure() {
            let device = AVCaptureDevice.default(
              .builtInWideAngleCamera,
              for: .video,
              position: .back
            )!
            let cameraInput = try! AVCaptureDeviceInput(device: device)
            guard session.canAddInput(cameraInput) else {
                return
            }
            session.addInput(cameraInput)
            guard session.canAddOutput(videoOutput) else {
                return
            }
            session.addOutput(videoOutput)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            let videoConnection = videoOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            session.startRunning()

            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            cnt += 1
            if cnt % limit != 0 {
                return
            }
            guard let buffer = sampleBuffer.imageBuffer else {
                return
            }
            let image = UIImage(pixelBuffer: buffer)!
                .croppingCenter(to: size)
            didReceiveFrameOutput?(image!)
        }
    }
}

extension UIImage {
    func croppingCenter(to size: CGSize) -> UIImage? {
        let scale = self.size.width / size.width
        let croppingSize: CGSize = imageOrientation.isLandscape ? size.switched : size
        let croppingRect: CGRect = .init(
            origin: CGPoint(
                x: (self.size.width - croppingSize.width) / 2 / scale,
                y: (self.size.height - croppingSize.height) / 2 / scale
            ),
            size: CGSize(
                width: size.width * scale,
                height: size.height * scale
            )
        )
        guard let cgImage: CGImage = self.cgImage?.cropping(to: croppingRect) else { return nil }
        let cropped: UIImage = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        return cropped
    }
}

extension CGSize {
    /// 反転させたサイズを返す
    var switched: CGSize {
        return CGSize(width: height, height: width)
    }
}

extension UIImage.Orientation {
    /// 画像が横向きであるか
    var isLandscape: Bool {
        switch self {
        case .up, .down, .upMirrored, .downMirrored:
            return false
        case .left, .right, .leftMirrored, .rightMirrored:
            return true
        @unknown default:
            fatalError()
        }
    }
}
