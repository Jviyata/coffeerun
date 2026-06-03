import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Tiny wrapper around `CIFilter.qrCodeGenerator()` that returns a crisp
/// `NSImage` ready to drop into SwiftUI. We oversample by `scale` so the
/// QR stays sharp even when stretched to ~180pt.
enum QRCodeGenerator {
    static func image(from string: String, scale: CGFloat = 10) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = "M"   // medium error correction
        guard let output = filter.outputImage else { return nil }

        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(
            cgImage: cg,
            size: NSSize(width: scaled.extent.width, height: scaled.extent.height)
        )
    }
}
