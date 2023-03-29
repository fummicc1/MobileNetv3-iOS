//
//  prepareImage.swift
//  MobileNetv3-Sample
//
//  Created by Fumiya Tanaka on 2023/03/29.
//

import Foundation
import UIKit


func prepareImage(_ image: UIImage) -> CVPixelBuffer? {
    let imageWidth = 224
    let imageHeight = 224

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, imageWidth, imageHeight, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

    guard status == kCVReturnSuccess else {
        return nil
    }

    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: pixelData, width: imageWidth, height: imageHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
        return nil
    }

    context.translateBy(x: 0, y: CGFloat(imageHeight))
    context.scaleBy(x: 1.0, y: -1.0)

    UIGraphicsPushContext(context)
    image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
    UIGraphicsPopContext()

    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
}

