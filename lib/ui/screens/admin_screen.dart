import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/weather_settings_api.dart';
import '../../util/exceptions.dart';
import '../../util/server_settings.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends DeferredState<AdminScreen> {
  late final TextEditingController _serverUrlController;
  late final TextEditingController _weatherSearchController;
  final _weatherApi = WeatherSettingsApi();
  List<WeatherLocationData> _weatherResults = [];
  WeatherLocationData? _selectedLocation;
  var _weatherSearchAttempted = false;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(
      text: ServerSettings.serverUrlOverride ?? '',
    );
    _weatherSearchController = TextEditingController();
  }

  @override
  Future<void> asyncInitState() async {
    await _loadWeatherLocation();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _weatherSearchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ServerSettings.setServerUrlOverride(_serverUrlController.text);
    final wsUrl = ServerSettings.toWebSocketUrl(
      ServerSettings.serverUrlOverride,
    );
    await ServerSettings.setWebSocketUrlOverride(wsUrl);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server URL saved')));
    }
  }

  Future<void> _clear() async {
    _serverUrlController.text = '';
    await ServerSettings.setServerUrlOverride(null);
    await ServerSettings.setWebSocketUrlOverride(null);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server URL cleared')));
    }
  }

  Future<void> _loadWeatherLocation() async {
    try {
      final loc = await _weatherApi.getLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedLocation = loc.geohash.isEmpty ? null : loc;
      });
    } on NetworkException {
      // Ignore if server isn't ready yet.
    }
  }

  Future<void> _searchWeather() async {
    final query = _weatherSearchController.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() {
      _weatherSearchAttempted = true;
    });
    try {
      final results = await _weatherApi.searchLocations(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _weatherResults = results;
      });
    } on NetworkException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Weather search failed: $e')));
    }
  }

  Future<void> _saveWeatherLocation() async {
    final selected = _selectedLocation;
    if (selected == null) {
      return;
    }
    try {
      await _weatherApi.setLocation(selected);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weather location saved')));
    } on NetworkException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Weather save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => DeferredBuilder(
    this,
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://your-server',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(onPressed: _save, child: const Text('Save')),
                const SizedBox(width: 12),
                TextButton(onPressed: _clear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Leave blank to use environment defaults or the current origin '
              'for web builds.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Weather Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weatherSearchController,
              decoration: const InputDecoration(
                labelText: 'Search by suburb or postcode',
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchWeather(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _searchWeather,
                  child: const Text('Search'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveWeatherLocation,
                  child: const Text('Save Location'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          if (_weatherResults.isNotEmpty)
            SizedBox(
              height: 200,
              child: RadioGroup<WeatherLocationData>(
                groupValue: _selectedLocation,
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                child: ListView.builder(
                  itemCount: _weatherResults.length,
                  itemBuilder: (context, index) {
                    final loc = _weatherResults[index];
                    final label = '${loc.name}, ${loc.state}';
                    return RadioListTile<WeatherLocationData>(
                      value: loc,
                      title: Text(label),
                      subtitle: Text(loc.geohash),
                    );
                  },
                ),
              ),
            )
          else if (_weatherSearchAttempted)
            Text(
              'No BOM data found. Try a nearby suburb or postcode.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (_selectedLocation != null)
            Text(
              'Selected: ${_selectedLocation!.name}, ${_selectedLocation!.state}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
