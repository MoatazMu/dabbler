import 'dart:typed_data';

import 'image_file_reader_stub.dart'
    if (dart.library.io) 'image_file_reader_io.dart'
    if (dart.library.html) 'image_file_reader_web.dart';

/// Abstraction for reading image bytes from a local file path.
///
/// On Web, file-path based reads are not supported; use bytes-based upload.
abstract class ImageFileReader {
  Future<bool> exists(String path);
  Future<int> length(String path);
  Future<Uint8List> readAsBytes(String path);
}

ImageFileReader createImageFileReader() => createImageFileReaderImpl();
