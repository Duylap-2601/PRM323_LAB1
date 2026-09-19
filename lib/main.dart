import 'package:flutter/material.dart';

import 'app.dart';
import 'core/environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.load();
  runApp(const AuditApp());
}
