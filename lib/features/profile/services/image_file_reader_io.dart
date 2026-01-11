import 'dart:io';
import 'dart:typed_data';

import 'image_file_reader.dart';

class _IoImageFileReader implements ImageFileReader {
  @override
  Future<bool> exists(String path) async {
    return File(path).exists();
  }

  @override
  Future<int> length(String path) async {
    return File(path).length();
  }

  @override
  Future<Uint8List> readAsBytes(String path) async {
    final bytes = await File(path).readAsBytes();
    return Uint8List.fromList(bytes);
  }
}

ImageFileReader createImageFileReaderImpl() => _IoImageFileReader();
