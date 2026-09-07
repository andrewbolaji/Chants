import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let canvasWidth = 1024
let canvasHeight = 500

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift scripts/render-google-feature-graphic.swift <output.png>\n", stderr)
    exit(64)
}

let projectRoot = FileManager.default.currentDirectoryPath
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])

func loadFont(_ relativePath: String, size: CGFloat) -> CTFont {
    let url = URL(fileURLWithPath: projectRoot).appendingPathComponent(relativePath)
    guard
        let provider = CGDataProvider(url: url as CFURL),
        let graphicsFont = CGFont(provider)
    else {
        fputs("Could not load font at \(relativePath)\n", stderr)
        exit(66)
    }
    return CTFontCreateWithGraphicsFont(graphicsFont, size, nil, nil)
}

func loadImage(_ relativePath: String) -> CGImage {
    let url = URL(fileURLWithPath: projectRoot).appendingPathComponent(relativePath)
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        fputs("Could not load image at \(relativePath)\n", stderr)
        exit(66)
    }
    return image
}

guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else {
    fputs("Could not create the sRGB color space\n", stderr)
    exit(70)
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    let components = [
        CGFloat((hex >> 16) & 0xff) / 255,
        CGFloat((hex >> 8) & 0xff) / 255,
        CGFloat(hex & 0xff) / 255,
        alpha,
    ]
    guard let value = CGColor(colorSpace: sRGB, components: components) else {
        fputs("Could not create an sRGB color\n", stderr)
        exit(70)
    }
    return value
}

let ink = color(0x080806)
let paper = color(0xf3efe6)
let gold = color(0xffc126)
let coral = color(0xee674f)

guard let context = CGContext(
    data: nil,
    width: canvasWidth,
    height: canvasHeight,
    bitsPerComponent: 8,
    bytesPerRow: canvasWidth * 4,
    space: sRGB,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fputs("Could not create drawing context\n", stderr)
    exit(70)
}

context.setFillColor(ink)
context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

let anton88 = loadFont("assets/fonts/Anton-Regular.ttf", size: 88)
let mono14 = loadFont("assets/fonts/SpaceMono-Bold.ttf", size: 14)
let mono12 = loadFont("assets/fonts/SpaceMono-Bold.ttf", size: 12)

@discardableResult
func drawText(
    _ text: String,
    font: CTFont,
    fill: CGColor,
    x: CGFloat,
    top: CGFloat,
    tracking: CGFloat = 0
) -> CGFloat {
    let attributes: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: fill,
        kCTKernAttributeName: tracking,
    ]
    let line = CTLineCreateWithAttributedString(
        CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)
    )
    context.textPosition = CGPoint(
        x: x,
        y: CGFloat(canvasHeight) - top - CTFontGetAscent(font)
    )
    CTLineDraw(line, context)
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

// The app mark is the only illustration. It is intentionally oversized and
// cropped like a supporter seen through the crowd, rather than framed as a logo.
let supporter = loadImage("store/assets/google-play-icon.png")
context.draw(supporter, in: CGRect(x: 726, y: 66, width: 344, height: 344))

// Small brand signature.
let markRect = CGRect(x: 56, y: 420, width: 30, height: 30)
context.setFillColor(gold)
context.fillEllipse(in: markRect)
context.setFillColor(ink)
context.fill(CGRect(x: 64, y: 427, width: 3, height: 8))
context.fill(CGRect(x: 70, y: 427, width: 3, height: 16))
context.fill(CGRect(x: 76, y: 427, width: 3, height: 11))
drawText("CHANTS FC", font: mono14, fill: paper, x: 100, top: 53, tracking: 1.2)

// One product promise. No feature grid, panels, or secondary campaign copy.
drawText("KNOW THE WORDS.", font: anton88, fill: paper, x: 56, top: 147, tracking: -0.35)
drawText("START THE NEXT ONE.", font: anton88, fill: gold, x: 56, top: 234, tracking: -0.35)

context.setFillColor(coral)
context.fill(CGRect(x: 56, y: 400, width: 44, height: 5))
drawText(
    "YOUR MATCHDAY SONGBOOK, MADE BY SUPPORTERS.",
    font: mono12,
    fill: color(0xf3efe6, alpha: 0.66),
    x: 56,
    top: 386,
    tracking: 0.65
)

guard
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    )
else {
    fputs("Could not create PNG destination\n", stderr)
    exit(70)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Could not write PNG\n", stderr)
    exit(74)
}
