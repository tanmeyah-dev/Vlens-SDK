import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<String> encodeLocalFileAsPdfBase64(String path) async {
  final bytes = await UserInfoDocumentPdfEncoder.encodeFile(File(path));
  return base64Encode(bytes).replaceAll(RegExp(r'\s'), '');
}

/// Builds a real PDF 1.4 (via the `pdf` package) that the one-click-apply
/// checker can parse. Hand-rolled Chromium lookalikes were still rejected
/// with business 417 even when the header and FlateDecode filter matched.
class UserInfoDocumentPdfEncoder {
  static const double _pageWidth = 846;
  static const double _pageHeight = 594;
  static const int _rasterWidth = 846;
  static const int _rasterHeight = 594;
  static const int _maxPdfBytes = 900000;

  static Future<Uint8List> encodeFile(File file) async {
    final bytes = await file.readAsBytes();
    if (_looksLikePdf(bytes)) {
      if (bytes.length > _maxPdfBytes) {
        throw const FormatException(
          'Selected PDF is too large. Pick a JPEG or PNG photo instead.',
        );
      }
      return bytes;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Could not decode the selected image.');
    }

    final photo = img.bakeOrientation(decoded).convert(numChannels: 3);
    var raster = _letterbox(photo, _rasterWidth, _rasterHeight);
    var pdf = await _buildPdf(raster);
    if (pdf.length > _maxPdfBytes) {
      raster = _letterbox(
        photo,
        (_rasterWidth * 0.75).round(),
        (_rasterHeight * 0.75).round(),
      );
      pdf = await _buildPdf(raster);
    }
    if (pdf.length > _maxPdfBytes) {
      throw const FormatException(
        'Encoded PDF is still too large for one-click-apply.',
      );
    }
    return pdf;
  }

  static bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2d;
  }

  static img.Image _letterbox(img.Image photo, int pageW, int pageH) {
    final canvas = img.Image(width: pageW, height: pageH, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    final scale = math.min(pageW / photo.width, pageH / photo.height);
    final fitted = img.copyResize(
      photo,
      width: (photo.width * scale).round().clamp(1, pageW),
      height: (photo.height * scale).round().clamp(1, pageH),
      interpolation: img.Interpolation.linear,
    );
    img.compositeImage(
      canvas,
      fitted,
      dstX: ((pageW - fitted.width) / 2).round(),
      dstY: ((pageH - fitted.height) / 2).round(),
    );
    return canvas;
  }

  static Future<Uint8List> _buildPdf(img.Image raster) async {
    final doc = pw.Document(
      version: PdfVersion.pdf_1_4,
      compress: true,
      title: 'Document',
      creator: 'Chromium',
      producer: 'Skia/PDF m79',
    );
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Image(
            pw.ImageImage(raster),
            fit: pw.BoxFit.contain,
            width: _pageWidth,
            height: _pageHeight,
          );
        },
      ),
    );
    return doc.save();
  }
}
