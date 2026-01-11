import 'dart:typed_data';

import 'image_file_reader.dart';

class _WebImageFileReader implements ImageFileReader {
  @override
  Future<bool> exists(String path) async {
    throw UnsupportedError(
      'File-path based image reads are not supported on Web. Use bytes-based upload.',
    );
  }

  @override
  Future<int> length(String path) async {
    throw UnsupportedError(
      'File-path based image reads are not supported on Web. Use bytes-based upload.',
    );
  }

  @override
  Future<Uint8List> readAsBytes(String path) async {
    throw UnsupportedError(
      'File-path based image reads are not supported on Web. Use bytes-based upload.',
    );
  }
}

ImageFileReader createImageFileReaderImpl() => _WebImageFileReader();
