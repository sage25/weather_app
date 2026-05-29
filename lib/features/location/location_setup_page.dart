import 'package:flutter/material.dart';

import '../../core/location/coordinates.dart';
import '../../core/location/location_store.dart';
import '../../core/location/location_validator.dart';

class LocationSetupPage extends StatefulWidget {
  const LocationSetupPage({
    super.key,
    required this.locationStore,
    required this.onSaved,
    this.initialCoordinates,
  });

  final LocationStore locationStore;
  final Coordinates? initialCoordinates;
  final Future<void> Function(Coordinates coordinates) onSaved;

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(
      text: widget.initialCoordinates?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.initialCoordinates?.longitude.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final Coordinates? coordinates = parseCoordinates(
      _latitudeController.text,
      _longitudeController.text,
    );
    if (coordinates == null) {
      return;
    }

    setState(() {
      _saving = true;
    });
    await widget.locationStore.save(coordinates);
    await widget.onSaved(coordinates);
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCoordinates == null ? '首次设置经纬度' : '修改经纬度'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            widget.initialCoordinates == null
                                ? '首次使用需要先填写位置'
                                : '修改后会立即生效',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '纬度范围 -90 到 90，经度范围 -180 到 180。',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '纬度',
                              hintText: '例如 29.56',
                            ),
                            validator: latitudeErrorText,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: '经度',
                              hintText: '例如 106.55',
                            ),
                            validator: longitudeErrorText,
                            onFieldSubmitted: (_) => _saving ? null : _submit(),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _saving ? null : _submit,
                            child: Text(_saving ? '保存中...' : '保存并进入天气页'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}