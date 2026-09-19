import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class LoadedDocument {
  final String fileName;
  final Uint8List bytes;
  const LoadedDocument({required this.fileName, required this.bytes});
}

class DocumentService {
  Future<PlatformFile?> pickDocument() async {
    return FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  Future<LoadedDocument> fromPickedFile(PlatformFile file) async {
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw const FormatException('Chỉ hỗ trợ file PDF.');
    }
    return LoadedDocument(fileName: file.name, bytes: await file.readAsBytes());
  }
}
