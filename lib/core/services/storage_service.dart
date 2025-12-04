import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> subirFirma(Uint8List datos, String nombreArchivo) async {
    try {
      final ref = _storage.ref().child('firmas/$nombreArchivo.png');
      print("📤 Intentando subir firma a: firmas/$nombreArchivo.png"); // LOG NUEVO

      final uploadTask = await ref.putData(datos, SettableMetadata(contentType: 'image/png'));

      final url = await uploadTask.ref.getDownloadURL();
      print("✅ Firma subida exitosamente: $url"); // LOG NUEVO
      return url;
    } catch (e) {
      print('❌ ERROR CRÍTICO SUBIENDO FIRMA: $e'); // LOG NUEVO
      return null;
    }
  }
}