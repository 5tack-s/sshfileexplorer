import '../model/file.dart' as F;

import 'dart:io';

class OwnRepository {
  static Future<void> delete(F.File file) async {
    var deletee = File(file.path);
    if (await deletee.exists()) {
      await deletee.delete();
    }
  }
}
