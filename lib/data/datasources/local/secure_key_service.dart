import 'dart:convert';
import 'dart:math';

import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyService {
  SecureKeyService(this._storage);

  final FlutterSecureStorage _storage;

  Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: AppConstants.dbEncryptionKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64UrlEncode(values);
    await _storage.write(key: AppConstants.dbEncryptionKey, value: key);
    return key;
  }
}
