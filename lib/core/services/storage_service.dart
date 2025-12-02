import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> subirFirma(Uint8List datos, String nombreArchivo) async {
    try {
      final ref = _storage.ref().child('firmas/$nombreArchivo.png');
      final uploadTask = await ref.putData(datos, SettableMetadata(contentType: 'image/png'));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error subiendo firma: $e');
      return null;
    }
  }
}