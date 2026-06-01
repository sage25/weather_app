import 'package:flutter/material.dart';

import '../../core/location/coordinates.dart';
import '../../core/location/location_store.dart';
import '../../core/weather/open_meteo_client.dart';
import '../../core/weather/open_meteo_exceptions.dart';
import '../../core/weather/weather_aggregation.dart';
import '../../core/weather/weather_home_layout.dart';
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
  bool _layoutSpecRecorded = false;

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
              final WeatherHomeLayoutSpec layoutSpec = buildWeatherHomeLayoutSpec(
                Size(constraints.maxWidth, constraints.maxHeight),
              );
              _recordLayoutSpecOnce(layoutSpec);

              return SafeArea(
                top: false,
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                  itemCount: summary.days.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _WeatherDayPanel(
                      summary: summary.days[index],
                      backgroundColor: index == 0 ? const Color(0xFFE7F0FF) : const Color(0xFFFFF0E4),
                      layoutSpec: layoutSpec,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _recordLayoutSpecOnce(WeatherHomeLayoutSpec layoutSpec) {
    if (_layoutSpecRecorded) {
      return;
    }

    _layoutSpecRecorded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      recordWeatherHomeLayoutSpec(layoutSpec);
    });
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
    required this.layoutSpec,
  });

  final WeatherDaySummary summary;
  final Color backgroundColor;
  final WeatherHomeLayoutSpec layoutSpec;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: backgroundColor,
        padding: layoutSpec.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _DayHeader(summary: summary),
            SizedBox(height: layoutSpec.pageHeaderGap),
            _PeriodHighlight(
              title: '凌晨',
              summaryText: summary.dawn.summaryText,
              layoutSpec: layoutSpec,
            ),
            SizedBox(height: layoutSpec.periodGap),
            _PeriodHighlight(
              title: '上午',
              summaryText: summary.morning.summaryText,
              layoutSpec: layoutSpec,
            ),
            SizedBox(height: layoutSpec.periodGap),
            _PeriodHighlight(
              title: '下午',
              summaryText: summary.afternoon.summaryText,
              layoutSpec: layoutSpec,
            ),
            SizedBox(height: layoutSpec.periodGap),
            _PeriodHighlight(
              title: '晚上',
              summaryText: summary.evening.summaryText,
              layoutSpec: layoutSpec,
            ),
            SizedBox(height: layoutSpec.twoHourSectionGap),
            Text(
              '2 小时分组',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: layoutSpec.periodGap),
            Expanded(
              child: _TwoHourGrid(
                periods: summary.twoHourWindows,
                layoutSpec: layoutSpec,
              ),
            ),
          ],
        ),
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
  const _PeriodHighlight({
    required this.title,
    required this.summaryText,
    required this.layoutSpec,
  });

  final String title;
  final String summaryText;
  final WeatherHomeLayoutSpec layoutSpec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: layoutSpec.periodCardPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(layoutSpec.periodCardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 60,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 10),
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

class _SmallPeriodCard extends StatelessWidget {
  const _SmallPeriodCard({required this.summary, required this.layoutSpec});

  final WeatherPeriodSummary summary;
  final WeatherHomeLayoutSpec layoutSpec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: layoutSpec.twoHourLabelWidth,
            child: Text(
              summary.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              summary.weatherLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: layoutSpec.twoHourTemperatureWidth,
            child: Text(
              summary.temperatureText,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoHourGrid extends StatelessWidget {
  const _TwoHourGrid({required this.periods, required this.layoutSpec});

  final List<WeatherPeriodSummary> periods;
  final WeatherHomeLayoutSpec layoutSpec;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = layoutSpec.twoHourCrossAxisCount;
        final int rows = (periods.length / columns).ceil();
        final double rowSpacing = layoutSpec.twoHourGridSpacing;
        final double itemWidth = (constraints.maxWidth - rowSpacing * (columns - 1)) / columns;
        final double itemHeight = (constraints.maxHeight - rowSpacing * (rows - 1)) / rows;
        final double childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: periods.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: rowSpacing,
            crossAxisSpacing: rowSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _SmallPeriodCard(summary: periods[index], layoutSpec: layoutSpec);
          },
        );
      },
    );
  }
}