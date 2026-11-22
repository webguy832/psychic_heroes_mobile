import 'file_picker_helper_stub.dart'
    if (dart.library.html) 'file_picker_helper_web.dart';
export 'file_picker_helper_stub.dart' show PickedFileData;

class FilePickerHelper {
  static Future<PickedFileData?> pickFile({List<String>? allowedExtensions}) {
    return FilePickerPlatform.pickFile(allowedExtensions: allowedExtensions);
  }
}
