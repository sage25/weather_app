import 'package:flutter/material.dart';

import '../../core/location/coordinates.dart';
import '../../core/location/location_store.dart';
import '../../core/weather/open_meteo_client.dart';
import '../../core/weather/open_meteo_exceptions.dart';
import '../../core/weather/weather_aggregation.dart';
import '../location/location_setup_page.dart';
import '../error/blank_error_page.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({
    super.key,
    required this.initialCoordinates,
    required this.locationStore,
  });

  final Coordinates initialCoordinates;
  final LocationStore locationStore;

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  late Coordinates _coordinates;
  late OpenMeteoClient _client;
  late Future<WeatherForecastSummary> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _coordinates = widget.initialCoordinates;
    _client = OpenMeteoClient();
    _forecastFuture = _loadForecast();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<WeatherForecastSummary> _loadForecast() async {
    final forecast = await _client.fetchForecast(
      latitude: _coordinates.latitude,
      longitude: _coordinates.longitude,
    );
    return buildWeatherForecastSummary(forecast);
  }

  void _reloadForecast() {
    setState(() {
      _forecastFuture = _loadForecast();
    });
  }

  Future<void> _openLocationEditor() async {
    final Coordinates? updated = await Navigator.of(context).push<Coordinates>(
      MaterialPageRoute<Coordinates>(
        builder: (BuildContext context) {
          return LocationSetupPage(
            locationStore: widget.locationStore,
            initialCoordinates: _coordinates,
            onSaved: (Coordinates coordinates) async {
              Navigator.of(context).pop(coordinates);
            },
          );
        },
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _coordinates = updated;
      _forecastFuture = _loadForecast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天气'),
        actions: <Widget>[
          IconButton(
            onPressed: _openLocationEditor,
            icon: const Icon(Icons.settings_outlined),
            tooltip: '修改经纬度',
          ),
        ],
      ),
      body: FutureBuilder<WeatherForecastSummary>(
        future: _forecastFuture,
        builder: (BuildContext context, AsyncSnapshot<WeatherForecastSummary> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _WeatherLoadingView();
          }

          if (snapshot.hasError) {
            final Object? error = snapshot.error;
            final String message = error is OpenMeteoException ? '天气加载失败，请重试' : '天气加载失败，请重试';
            return BlankErrorPage(
              message: message,
              onRetry: _reloadForecast,
            );
          }

          final WeatherForecastSummary summary = snapshot.data!;
          if (summary.days.isEmpty) {
            return BlankErrorPage(
              message: '天气加载失败，请重试',
              onRetry: _reloadForecast,
            );
          }

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _WeatherDayPanel(
                      summary: summary.days.first,
                      backgroundColor: const Color(0xFFE7F0FF),
                      minHeight: constraints.maxHeight,
                    ),
                    if (summary.days.length > 1)
                      _WeatherDayPanel(
                        summary: summary.days[1],
                        backgroundColor: const Color(0xFFFFF0E4),
                        minHeight: constraints.maxHeight,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WeatherLoadingView extends StatelessWidget {
  const _WeatherLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _WeatherDayPanel extends StatelessWidget {
  const _WeatherDayPanel({
    required this.summary,
    required this.backgroundColor,
    required this.minHeight,
  });

  final WeatherDaySummary summary;
  final Color backgroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DayHeader(summary: summary),
          const SizedBox(height: 20),
          _PeriodHighlight(
            title: '上午',
            summaryText: summary.morning.summaryText,
          ),
          const SizedBox(height: 12),
          _PeriodHighlight(
            title: '下午',
            summaryText: summary.afternoon.summaryText,
          ),
          const SizedBox(height: 22),
          Text(
            '6 小时总览',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.sixHourWindows.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.85,
            ),
            itemBuilder: (BuildContext context, int index) {
              final WeatherPeriodSummary period = summary.sixHourWindows[index];
              return _PeriodCard(summary: period);
            },
          ),
          const SizedBox(height: 22),
          Text(
            '2 小时分组',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.twoHourWindows.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (BuildContext context, int index) {
              final WeatherPeriodSummary period = summary.twoHourWindows[index];
              return _SmallPeriodCard(summary: period);
            },
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.summary});

  final WeatherDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          summary.dayLabel,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            summary.dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ),
      ],
    );
  }
}

class _PeriodHighlight extends StatelessWidget {
  const _PeriodHighlight({required this.title, required this.summaryText});

  final String title;
  final String summaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 66,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              summaryText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.summary});

  final WeatherPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            summary.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.summaryText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SmallPeriodCard extends StatelessWidget {
  const _SmallPeriodCard({required this.summary});

  final WeatherPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            summary.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.summaryText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}