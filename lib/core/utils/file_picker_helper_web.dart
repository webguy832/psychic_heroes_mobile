// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'file_picker_helper_stub.dart';

class FilePickerPlatform {
  static Future<PickedFileData?> pickFile({List<String>? allowedExtensions}) async {
    final completer = Completer<PickedFileData?>();
    final input = html.FileUploadInputElement();
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      input.accept = allowedExtensions.map((e) => e.startsWith('.') ? e : '.$e').join(',');
    }
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result != null) {
          final bytes = (result as dynamic) is List<int>
              ? List<int>.from(result as dynamic)
              : (result as html.ByteBuffer).asUint8List();
          completer.complete(PickedFileData(
            name: file.name,
            bytes: bytes,
            size: file.size,
          ));
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((_) => completer.complete(null));
    });

    return completer.future;
  }
}
