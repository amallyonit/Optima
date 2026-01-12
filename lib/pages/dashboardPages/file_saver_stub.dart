import 'dart:typed_data';

void saveFileForWeb(Uint8List? fileBytes, String fileName) {
  throw UnsupportedError(
      "Web file saver is not supported on non-web platforms.");
}
