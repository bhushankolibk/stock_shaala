import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../data/models/ebook_model.dart';

/// Downloads ebook PDFs to a local cache (keyed by id + version, so a
/// content update invalidates the old file automatically) and renders a
/// first-page thumbnail to use as the cover — there's no separate cover
/// image, the book's own first page *is* the cover.
class EbookDownloadService {
  final Dio _dio;
  EbookDownloadService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 3),
            ));

  final Map<String, Uint8List> _coverCache = {};

  Future<File> localFile(Ebook book) async {
    final dir = await getApplicationDocumentsDirectory();
    final ebooksDir = Directory('${dir.path}/ebooks');
    if (!await ebooksDir.exists()) {
      await ebooksDir.create(recursive: true);
    }
    final file = File('${ebooksDir.path}/${book.id}_v${book.version}.pdf');
    if (await file.exists() && await file.length() > 0) return file;
    await _dio.download(book.pdfUrl, file.path);
    return file;
  }

  Future<Uint8List?> coverThumbnail(Ebook book) async {
    final cacheKey = '${book.id}_v${book.version}';
    final cached = _coverCache[cacheKey];
    if (cached != null) return cached;

    final file = await localFile(book);
    final doc = await PdfDocument.openFile(file.path);
    try {
      final page = await doc.getPage(1);
      try {
        final image = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        final bytes = image?.bytes;
        if (bytes != null) _coverCache[cacheKey] = bytes;
        return bytes;
      } finally {
        await page.close();
      }
    } finally {
      await doc.close();
    }
  }
}
