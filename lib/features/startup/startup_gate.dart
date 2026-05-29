import 'package:flutter/material.dart';

import '../../core/location/coordinates.dart';
import '../../core/location/location_store.dart';
import '../error/blank_error_page.dart';
import '../location/location_setup_page.dart';
import '../weather/weather_home_page.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.locationStore});

  final LocationStore locationStore;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<Coordinates?> _initialCoordinatesFuture;
  Coordinates? _initialCoordinates;

  @override
  void initState() {
    super.initState();
    _initialCoordinatesFuture = widget.locationStore.read();
  }

  Future<void> _reload() async {
    setState(() {
      _initialCoordinatesFuture = widget.locationStore.read();
    });
  }

  Future<void> _handleInitialSave(Coordinates coordinates) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _initialCoordinates = coordinates;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCoordinates != null) {
      return WeatherHomePage(
        initialCoordinates: _initialCoordinates!,
        locationStore: widget.locationStore,
      );
    }

    return FutureBuilder<Coordinates?>(
      future: _initialCoordinatesFuture,
      builder: (BuildContext context, AsyncSnapshot<Coordinates?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupLoadingPage();
        }

        if (snapshot.hasError) {
          return BlankErrorPage(
            message: '启动失败，请重试',
            onRetry: _reload,
          );
        }

        final Coordinates? coordinates = snapshot.data;
        if (coordinates == null) {
          return LocationSetupPage(
            locationStore: widget.locationStore,
            onSaved: _handleInitialSave,
          );
        }

        return WeatherHomePage(
          initialCoordinates: coordinates,
          locationStore: widget.locationStore,
        );
      },
    );
  }
}

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}