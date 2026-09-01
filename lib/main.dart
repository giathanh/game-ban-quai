import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/platform/orientation_lock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OrientationLock.portrait();
  runApp(const BanHeoApp());
}
