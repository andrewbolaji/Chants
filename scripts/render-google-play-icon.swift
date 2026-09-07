#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGBA {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

private let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("Usage: render-google-play-icon.swift <source.png> <output.png>\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])
guard
    let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
else {
    fputs("Could not read the source PNG.\n", stderr)
    exit(65)
}

let sourceWidth = image.width
let sourceHeight = image.height
let sourceBytesPerRow = sourceWidth * 4
var sourceBytes = [UInt8](repeating: 0, count: sourceBytesPerRow * sourceHeight)
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let sourceContext = CGContext(
    data: &sourceBytes,
    width: sourceWidth,
    height: sourceHeight,
    bitsPerComponent: 8,
    bytesPerRow: sourceBytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Could not create the source pixel buffer.\n", stderr)
    exit(70)
}
sourceContext.draw(image, in: CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight))

let background = RGBA(
    red: Double(sourceBytes[0]),
    green: Double(sourceBytes[1]),
    blue: Double(sourceBytes[2]),
    alpha: 1
)
let brandColors = [
    RGBA(red: 237, green: 148, blue: 29, alpha: 1),
    RGBA(red: 250, green: 198, blue: 0, alpha: 1),
]

func separatedPixel(at offset: Int) -> RGBA {
    let observed = (
        red: Double(sourceBytes[offset]),
        green: Double(sourceBytes[offset + 1]),
        blue: Double(sourceBytes[offset + 2])
    )
    var best = RGBA(red: 0, green: 0, blue: 0, alpha: 0)
    var bestResidual = Double.greatestFiniteMagnitude

    for color in brandColors {
        let delta = (
            red: color.red - background.red,
            green: color.green - background.green,
            blue: color.blue - background.blue
        )
        let observedDelta = (
            red: observed.red - background.red,
            green: observed.green - background.green,
            blue: observed.blue - background.blue
        )
        let denominator = delta.red * delta.red + delta.green * delta.green + delta.blue * delta.blue
        let projected = (
            observedDelta.red * delta.red
                + observedDelta.green * delta.green
                + observedDelta.blue * delta.blue
        ) / denominator
        let alpha = min(1, max(0, projected))
        let reconstructed = (
            red: background.red + alpha * delta.red,
            green: background.green + alpha * delta.green,
            blue: background.blue + alpha * delta.blue
        )
        let residual = pow(observed.red - reconstructed.red, 2)
            + pow(observed.green - reconstructed.green, 2)
            + pow(observed.blue - reconstructed.blue, 2)
        if residual < bestResidual {
            bestResidual = residual
            best = RGBA(red: color.red, green: color.green, blue: color.blue, alpha: alpha)
        }
    }

    if best.alpha < 0.015 || bestResidual > 900 {
        return RGBA(red: 0, green: 0, blue: 0, alpha: 0)
    }
    return best
}

var separated = [RGBA](
    repeating: RGBA(red: 0, green: 0, blue: 0, alpha: 0),
    count: sourceWidth * sourceHeight
)
var minimumX = sourceWidth
var minimumY = sourceHeight
var maximumX = 0
var maximumY = 0

for y in 0..<sourceHeight {
    for x in 0..<sourceWidth {
        let index = y * sourceWidth + x
        let pixel = separatedPixel(at: y * sourceBytesPerRow + x * 4)
        separated[index] = pixel
        if pixel.alpha >= 0.02 {
            minimumX = min(minimumX, x)
            minimumY = min(minimumY, y)
            maximumX = max(maximumX, x)
            maximumY = max(maximumY, y)
        }
    }
}

guard minimumX <= maximumX, minimumY <= maximumY else {
    fputs("The source did not contain the expected supporter mark.\n", stderr)
    exit(65)
}

let outputWidth = 512
let outputHeight = 512
let markWidth = maximumX - minimumX + 1
let markHeight = maximumY - minimumY + 1
let targetExtent = 308.0
let scale = min(targetExtent / Double(markWidth), targetExtent / Double(markHeight))
let targetWidth = Double(markWidth) * scale
let targetHeight = Double(markHeight) * scale
let targetLeft = (Double(outputWidth) - targetWidth) / 2
let targetTop = (Double(outputHeight) - targetHeight) / 2
var outputBytes = [UInt8](repeating: 0, count: outputWidth * outputHeight * 4)

func sample(_ sourceX: Double, _ sourceY: Double) -> RGBA {
    let x0 = max(minimumX, min(maximumX, Int(floor(sourceX))))
    let y0 = max(minimumY, min(maximumY, Int(floor(sourceY))))
    let x1 = min(maximumX, x0 + 1)
    let y1 = min(maximumY, y0 + 1)
    let xWeight = sourceX - floor(sourceX)
    let yWeight = sourceY - floor(sourceY)
    let points = [
        (separated[y0 * sourceWidth + x0], (1 - xWeight) * (1 - yWeight)),
        (separated[y0 * sourceWidth + x1], xWeight * (1 - yWeight)),
        (separated[y1 * sourceWidth + x0], (1 - xWeight) * yWeight),
        (separated[y1 * sourceWidth + x1], xWeight * yWeight),
    ]
    let alpha = points.reduce(0.0) { $0 + $1.0.alpha * $1.1 }
    guard alpha > 0 else {
        return RGBA(red: 0, green: 0, blue: 0, alpha: 0)
    }
    let red = points.reduce(0.0) { $0 + $1.0.red * $1.0.alpha * $1.1 } / alpha
    let green = points.reduce(0.0) { $0 + $1.0.green * $1.0.alpha * $1.1 } / alpha
    let blue = points.reduce(0.0) { $0 + $1.0.blue * $1.0.alpha * $1.1 } / alpha
    return RGBA(red: red, green: green, blue: blue, alpha: alpha)
}

for y in 0..<outputHeight {
    for x in 0..<outputWidth {
        let centeredX = Double(x) + 0.5
        let centeredY = Double(y) + 0.5
        guard
            centeredX >= targetLeft,
            centeredX < targetLeft + targetWidth,
            centeredY >= targetTop,
            centeredY < targetTop + targetHeight
        else {
            continue
        }
        let sourceX = Double(minimumX) + (centeredX - targetLeft) / scale - 0.5
        let sourceY = Double(minimumY) + (centeredY - targetTop) / scale - 0.5
        let pixel = sample(sourceX, sourceY)
        let offset = (y * outputWidth + x) * 4
        let alpha = min(1, max(0, pixel.alpha))
        outputBytes[offset] = UInt8((pixel.red * alpha).rounded())
        outputBytes[offset + 1] = UInt8((pixel.green * alpha).rounded())
        outputBytes[offset + 2] = UInt8((pixel.blue * alpha).rounded())
        outputBytes[offset + 3] = UInt8((255 * alpha).rounded())
    }
}

guard let outputContext = CGContext(
    data: &outputBytes,
    width: outputWidth,
    height: outputHeight,
    bitsPerComponent: 8,
    bytesPerRow: outputWidth * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
), let outputImage = outputContext.makeImage() else {
    fputs("Could not create the output pixel buffer.\n", stderr)
    exit(70)
}

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("Could not create the output PNG.\n", stderr)
    exit(73)
}
CGImageDestinationAddImage(destination, outputImage, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Could not write the output PNG.\n", stderr)
    exit(74)
}

print("Rendered transparent 512 by 512 Google Play icon at \(outputURL.path)")
