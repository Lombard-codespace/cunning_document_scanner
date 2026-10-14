//
//  ScannerOptions.swift
//  cunning_document_scanner
//
//  Created by Maurits van Beusekom on 15/10/2024.
//

import Foundation

enum CunningScannerImageFormat: String {
    case jpg
    case png
}

struct CunningScannerOptions {
    let imageFormat: CunningScannerImageFormat
    let jpgCompressionQuality: Double
    let singleDocumentMode: Bool
    let frameColor: String?
    /// Longest side in pixels that scanned pages are scaled down to. nil keeps the original resolution.
    let maxImageDimension: Double?
    
    init() {
        self.imageFormat = CunningScannerImageFormat.png
        self.jpgCompressionQuality = 1.0
        self.singleDocumentMode = false
        self.frameColor = nil
        self.maxImageDimension = nil
    }
    
    init(imageFormat: CunningScannerImageFormat) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = 1.0
        self.singleDocumentMode = false
        self.frameColor = nil
        self.maxImageDimension = nil
    }
    
    init(imageFormat: CunningScannerImageFormat, jpgCompressionQuality: Double) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = jpgCompressionQuality
        self.singleDocumentMode = false
        self.frameColor = nil
        self.maxImageDimension = nil
    }
    
    init(imageFormat: CunningScannerImageFormat, jpgCompressionQuality: Double, singleDocumentMode: Bool, frameColor: String?, maxImageDimension: Double? = nil) {
        self.imageFormat = imageFormat
        self.jpgCompressionQuality = jpgCompressionQuality
        self.singleDocumentMode = singleDocumentMode
        self.frameColor = frameColor
        self.maxImageDimension = maxImageDimension
    }
    
    static func fromArguments(args: Any?) -> CunningScannerOptions {
        if (args == nil) {
            return CunningScannerOptions()
        }
        
        let arguments = args as? Dictionary<String, Any>
    
        // Check for top-level singleDocumentMode first (for Android compatibility)
        let topLevelSingleDocumentMode: Bool = (arguments?["singleDocumentMode"] as? Bool) ?? false
        let topLevelFrameColor: String? = arguments?["frameColor"] as? String
        
        if arguments == nil || arguments!.keys.contains("iosScannerOptions") == false {
            // If no iosScannerOptions, use top-level values or defaults
            return CunningScannerOptions(
                imageFormat: CunningScannerImageFormat.png,
                jpgCompressionQuality: 1.0,
                singleDocumentMode: topLevelSingleDocumentMode,
                frameColor: topLevelFrameColor
            )
        }
        
        guard let scannerOptionsDict = arguments!["iosScannerOptions"] as? Dictionary<String, Any> else {
            return CunningScannerOptions(
                imageFormat: CunningScannerImageFormat.png,
                jpgCompressionQuality: 1.0,
                singleDocumentMode: topLevelSingleDocumentMode,
                frameColor: topLevelFrameColor
            )
        }
        let imageFormat: String = (scannerOptionsDict["imageFormat"] as? String) ?? "png"
        let jpgCompressionQuality: Double = (scannerOptionsDict["jpgCompressionQuality"] as? Double) ?? 1.0
        // Use singleDocumentMode from iosScannerOptions if provided, otherwise use top-level
        let singleDocumentMode: Bool = (scannerOptionsDict["singleDocumentMode"] as? Bool) ?? topLevelSingleDocumentMode
        // Use frameColor from iosScannerOptions if provided, otherwise use top-level
        let frameColor: String? = (scannerOptionsDict["frameColor"] as? String) ?? topLevelFrameColor
        let maxImageDimension: Double? = (scannerOptionsDict["maxImageDimension"] as? NSNumber)?.doubleValue
            
        return CunningScannerOptions(
            imageFormat: CunningScannerImageFormat(rawValue: imageFormat) ?? CunningScannerImageFormat.png,
            jpgCompressionQuality: jpgCompressionQuality,
            singleDocumentMode: singleDocumentMode,
            frameColor: frameColor,
            maxImageDimension: maxImageDimension
        )
    }
}
