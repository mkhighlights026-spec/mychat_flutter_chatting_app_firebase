import 'package:uuid/uuid.dart';

class DeviceHelper {
  static String generateDeviceId() {
    return const Uuid().v4();
  }
}
