import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/weather_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ],
  );
  runApp(const WeatherApp());
}
