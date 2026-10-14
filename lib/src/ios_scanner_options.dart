import 'ios_image_format.dart';

/// Different options that modify the behavior of the document scanner on iOS.
///
/// The [imageFormat] specifies the format of the output image file. Available
/// options are [IosImageFormat.jpeg] or [IosImageFormat.png]. Default value is
/// [IosImageFormat.png].
///
/// If [imageFormat] is set to [IosImageFormat.jpeg] the [jpgCompressionQuality]
/// can be used to control the quality of the resulting JPEG image. The value
/// 0.0 represents the maximum compression (or lowest quality) while the value
/// 1.0 represents the least compression (or best quality). Default value is 1.0.
///
/// The [singleDocumentMode] when set to true, ensures only the first document/page
/// is processed and returned, even if the user scans multiple pages.
///
/// The [frameColor] allows customization of the document detection frame color.
/// Note: This feature is not available on iOS as VNDocumentCameraViewController
/// uses system UI that cannot be customized. This parameter is included for API
/// consistency but will be ignored on iOS.
///
/// The [maxImageDimension] scales scanned pages down so their longest side is at
/// most this many pixels before they are saved. This reduces memory usage and file
/// size. Default value is null, which keeps the original resolution.
class IosScannerOptions {
  /// Creates a [IosScannerOptions].
  const IosScannerOptions({
    this.imageFormat = IosImageFormat.png,
    this.jpgCompressionQuality = 1.0,
    this.singleDocumentMode = false,
    this.frameColor,
    this.maxImageDimension,
  });

  final IosImageFormat imageFormat;

  /// The quality of the resulting JPEG image, expressed as a value from 0.0 to
  /// 1.0.
  ///
  /// The value 0.0 represents the maximum compression (or lowest quality) while
  /// the value 1.0 represents the least compression (or best quality). The
  /// [jpgCompressionQuality] only has an effect if the [imageFormat] is set to
  /// [IosImageFormat.jpeg] and is ignored otherwise.
  final double jpgCompressionQuality;

  /// When true, only the first scanned document/page will be processed and returned.
  /// Default value is false.
  final bool singleDocumentMode;

  /// The color of the document detection frame/overlay.
  /// Supports hex colors (e.g., "#FF0000" or "FF0000") or named colors (e.g., "red", "blue").
  /// Note: This feature is not available on iOS and will be ignored.
  final String? frameColor;

  /// The maximum length in pixels of the longest side of a saved page.
  /// Pages larger than this are scaled down before saving. Default value is null,
  /// which keeps the original resolution.
  final int? maxImageDimension;
}
