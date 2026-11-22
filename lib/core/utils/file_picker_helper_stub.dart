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

class FilePickerPlatform {
  static Future<PickedFileData?> pickFile({List<String>? allowedExtensions}) async {
    return null;
  }
}
