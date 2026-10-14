import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftCunningDocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
  // Set while a scan is in progress, including the background processing after the scanner is dismissed.
  // Only touched on the main thread.
  var resultChannel: FlutterResult?
  var presentingController: VNDocumentCameraViewController?
  var scannerOptions: CunningScannerOptions = CunningScannerOptions()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cunning_document_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftCunningDocumentScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getPictures" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard resultChannel == nil else {
      result(FlutterError(code: "ALREADY_ACTIVE", message: "A document scan is already in progress", details: nil))
      return
    }

    guard VNDocumentCameraViewController.isSupported else {
      result(FlutterError(code: "UNAVAILABLE", message: "Document camera is not available on this device", details: nil))
      return
    }

    guard let presentingViewController = topViewController() else {
      result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available to present the document camera", details: nil))
      return
    }

    scannerOptions = CunningScannerOptions.fromArguments(args: call.arguments)
    resultChannel = result

    let scanner = VNDocumentCameraViewController()
    scanner.delegate = self
    presentingController = scanner
    presentingViewController.present(scanner, animated: true)
  }

  public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    guard let result = resultChannel else {
      controller.dismiss(animated: true)
      return
    }

    // Copy the options on the main thread so the background work never reads shared state
    let options = scannerOptions

    // Dismiss the scanner immediately to return to the app as fast as possible and process the pages
    // in the background. The result is delivered once both are done; until then resultChannel stays set,
    // so new scans are rejected instead of being presented while the scanner is still dismissing.
    let group = DispatchGroup()
    var filePaths: [String] = []

    group.enter()
    controller.dismiss(animated: true) { group.leave() }

    group.enter()
    DispatchQueue.global(qos: .userInitiated).async {
      filePaths = SwiftCunningDocumentScannerPlugin.saveScannedPages(scan, options: options)
      group.leave()
    }

    group.notify(queue: .main) {
      self.presentingController = nil
      self.resultChannel = nil
      result(filePaths)
    }
  }

  public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    finish(controller, with: nil)
  }

  public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    finish(controller, with: FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
  }

  private func finish(_ controller: VNDocumentCameraViewController, with value: Any?) {
    guard let result = resultChannel else {
      controller.dismiss(animated: true)
      return
    }

    controller.dismiss(animated: true) {
      self.presentingController = nil
      self.resultChannel = nil
      result(value)
    }
  }

  /// Writes the scanned pages to the temporary directory and returns the paths of the files that were written.
  /// In singleDocumentMode only the first page is saved.
  private static func saveScannedPages(_ scan: VNDocumentCameraScan, options: CunningScannerOptions) -> [String] {
    guard let directory = scansDirectory() else { return [] }

    let batchId = UUID().uuidString
    let pageCount = options.singleDocumentMode ? min(1, scan.pageCount) : scan.pageCount
    var filePaths: [String] = []

    for i in 0 ..< pageCount {
      // Release each page's bitmap and encoded data before processing the next one
      autoreleasepool {
        let page = downscaled(scan.imageOfPage(at: i), maxDimension: options.maxImageDimension)
        let url = directory.appendingPathComponent("\(batchId)-\(i).\(options.imageFormat.rawValue)")

        let data: Data?
        switch options.imageFormat {
        case CunningScannerImageFormat.jpg:
          data = page.jpegData(compressionQuality: options.jpgCompressionQuality)
        case CunningScannerImageFormat.png:
          data = page.pngData()
        }

        guard let data = data else { return }
        do {
          try data.write(to: url, options: .atomic)
          filePaths.append(url.path)
        } catch {
          NSLog("cunning_document_scanner: failed to write page \(i): \(error.localizedDescription)")
        }
      }
    }

    return filePaths
  }

  /// Scans are written to the temporary directory so they are never backed up and are purged by the system.
  private static func scansDirectory() -> URL? {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("cunning_document_scanner", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      return directory
    } catch {
      NSLog("cunning_document_scanner: failed to create scans directory: \(error.localizedDescription)")
      return nil
    }
  }

  private static func downscaled(_ image: UIImage, maxDimension: Double?) -> UIImage {
    guard let maxDimension = maxDimension, maxDimension > 0 else { return image }

    let longestSide = max(image.size.width, image.size.height)
    guard longestSide > CGFloat(maxDimension) else { return image }

    let scale = CGFloat(maxDimension) / longestSide
    let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }

  private func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    var topController = keyWindow?.rootViewController
    while let presented = topController?.presentedViewController, !presented.isBeingDismissed {
      topController = presented
    }
    return topController
  }
}
