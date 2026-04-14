import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class EncryptionHelper {
  static encrypt.Key _getKey(String keyText) {
    return encrypt.Key.fromUtf8(
      keyText.padRight(32).substring(0, 32),
    );
  }

  static String encryptText(String plainText, String keyText) {
    final key = _getKey(keyText);
    final iv = encrypt.IV.fromSecureRandom(16); // ✅ random IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Store IV + Cipher together
    return base64Encode(iv.bytes) + ":" + encrypted.base64;
  }

  static String decryptText(String encryptedText, String keyText) {
    final key = _getKey(keyText);
    final parts = encryptedText.split(":");

    final iv = encrypt.IV(base64Decode(parts[0]));
    final cipher = parts[1];

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(cipher, iv: iv);
  }
}
