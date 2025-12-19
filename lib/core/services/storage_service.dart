import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Subir archivo genérico (bytes)
  Future<String> uploadFile(Uint8List data, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Error subiendo archivo: $e");
    }
  }

  // ✅ MÉTODO QUE FALTABA
  Future<String> uploadImage(Uint8List data, String path) async {
    // Es lo mismo que uploadFile pero semánticamente separado por si queremos comprimir
    return await uploadFile(data, path);
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignorar si no existe
    }
  }
}
