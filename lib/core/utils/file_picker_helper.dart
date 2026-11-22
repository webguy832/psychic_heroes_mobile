import 'file_picker_helper_stub.dart'
    if (dart.library.html) 'file_picker_helper_web.dart';

class PickedFileData {
  final String name;
  final List<int> bytes;
  final int size;

  PickedFileData({
    required this.name,
    required this.bytes,
    required this.size,
  });
}

class FilePickerHelper {
  static Future<PickedFileData?> pickFile({List<String>? allowedExtensions}) {
    return FilePickerPlatform.pickFile(allowedExtensions: allowedExtensions);
  }
}
