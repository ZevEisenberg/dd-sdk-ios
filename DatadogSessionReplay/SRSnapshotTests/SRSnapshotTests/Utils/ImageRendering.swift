/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import UIKit
@testable import DatadogSessionReplay

/// Renders application window into image.
internal func renderImage(for window: UIWindow) -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    return renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
}

/// Renders wireframes into image.
internal func renderImage(for wireframes: [SRWireframe]) -> UIImage {
    guard !wireframes.isEmpty else {
        return UIImage()
    }

    let frame = wireframes[0].toFrame()
    let canvas = FramerCanvas.create(size: CGSize(width: frame.width, height: frame.height))
    canvas.draw(blueprint: Blueprint(id: "snapshot", frames: wireframes.map { $0.toFrame() }))
    return canvas.image
}

// MARK: - Wireframes Rendering with Framer

private extension SRWireframe {
    func toFrame() -> BlueprintFrame {
        switch self {
        case .shapeWireframe(let shape):
            return shape.toFrame()
        case .textWireframe(let text):
            return text.toFrame()
        case .imageWireframe(value: let image):
            return image.toFrame()
        }
    }
}

private extension SRShapeWireframe {
    func toFrame() -> BlueprintFrame {
        BlueprintFrame(
            x: CGFloat(x),
            y: CGFloat(y),
            width: CGFloat(width),
            height: CGFloat(height),
            style: frameStyle(border: border, style: shapeStyle),
            content: nil
        )
    }
}

private extension SRTextWireframe {
    func toFrame() -> BlueprintFrame {
        BlueprintFrame(
            x: CGFloat(x),
            y: CGFloat(y),
            width: CGFloat(width),
            height: CGFloat(height),
            style: frameStyle(border: border, style: shapeStyle),
            content: frameContent(text: text, textStyle: textStyle, textPosition: textPosition)
        )
    }
}

private extension SRImageWireframe {
    func toFrame() -> BlueprintFrame {
        BlueprintFrame(
            x: CGFloat(x),
            y: CGFloat(y),
            width: CGFloat(width),
            height: CGFloat(height),
            style: .init(lineWidth: 1, lineColor: .black, fillColor: .red),
            annotation: .init(
                text: "IMG \(width) x \(height)",
                style: .init(size: .small, position: .top, alignment: .trailing)
            )
        )
    }
}

private func frameStyle(border: SRShapeBorder?, style: SRShapeStyle?) -> BlueprintFrameStyle {
    var fs = BlueprintFrameStyle(
        lineWidth: 0,
        lineColor: .clear,
        fillColor: .clear,
        cornerRadius: 0,
        opacity: 1
    )

    if let border = border {
        fs.lineWidth = CGFloat(border.width)
        fs.lineColor = UIColor(hexString: border.color)
    }

    if let style = style {
        fs.fillColor = style.backgroundColor.flatMap { UIColor(hexString: $0) } ?? fs.fillColor
        fs.cornerRadius = style.cornerRadius.flatMap { CGFloat($0) } ?? fs.cornerRadius
        fs.opacity = style.opacity.flatMap { CGFloat($0) } ?? fs.opacity
    }

    return fs
}

private func frameContent(text: String, textStyle: SRTextStyle?, textPosition: SRTextPosition?) -> BlueprintFrameContent {
    var fc = BlueprintFrameContent(
        text: text,
        textColor: .clear,
        font: .systemFont(ofSize: 8)
    )

    if let textStyle = textStyle {
        fc.textColor = UIColor(hexString: textStyle.color)
        fc.font = .systemFont(ofSize: CGFloat(textStyle.size))
    }

    if let textPosition = textPosition {
        switch textPosition.alignment?.horizontal {
        case .left?:    fc.horizontalAlignment = .leading
        case .center?:  fc.horizontalAlignment = .center
        case .right?:   fc.horizontalAlignment = .trailing
        default:        break
        }
        switch textPosition.alignment?.vertical {
        case .top?:     fc.verticalAlignment = .leading
        case .center?:  fc.verticalAlignment = .center
        case .bottom?:  fc.verticalAlignment = .trailing
        default:        break
        }
    }

    return fc
}

private extension UIColor {
    convenience init(hexString: String) {
        precondition(hexString.count == 9, "Invalid `hexString` - expected 9 characters, got '\(hexString)'")
        precondition(hexString.hasPrefix("#"), "Invalid `hexString` - expected # prefix, got '\(hexString)'")

        guard let hex8 = UInt64(hexString.dropFirst(), radix: 16) else {
            preconditionFailure("Invalid `hexString`` - expected hexadecimal value, got '\(hexString)'")
        }

        let mask: UInt64 = 0x00000000FF
        self.init(
            red: CGFloat((hex8 >> 24) & mask) / CGFloat(255),
            green: CGFloat((hex8 >> 16) & mask) / CGFloat(255),
            blue: CGFloat((hex8 >> 8) & mask) / CGFloat(255),
            alpha: CGFloat(hex8  & mask) / CGFloat(255)
        )
    }
}
