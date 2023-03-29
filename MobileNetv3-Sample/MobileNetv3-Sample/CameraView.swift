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
        Coordinator()
    }

    func makeUIView(context: Context) -> UICameraView {
        let view = UICameraView(frame: .zero)
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.frame = CGRect(origin: .zero, size: size)
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
        let sessionQueue: DispatchQueue = .init(label: "")
        let videoOutput = AVCaptureVideoDataOutput()

        var didReceiveFrameOutput: ((UIImage) -> Void)?

        var cnt: Int = 0
        let limit: Int = 60

        override init() {
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
              position: .front
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
            let image = UIImage(pixelBuffer: buffer)
            didReceiveFrameOutput?(image!)
        }
    }
}
