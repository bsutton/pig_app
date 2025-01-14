// lighting_view_screen.dart
import 'package:flutter/material.dart';

import '../../api/lighting.dart';
import '../../api/lighting_info.dart';
import '../../util/exceptions.dart';
import '../widgets/async_state.dart';
import '../widgets/hmb_toast.dart';

class LightingViewScreen extends StatefulWidget {
  const LightingViewScreen({super.key});

  @override
  _LightingViewScreenState createState() => _LightingViewScreenState();
}

class _LightingViewScreenState extends AsyncState<LightingViewScreen> {
  late Future<List<LightingInfo>> _lightingFuture;
  final api = LightingApi();

  @override
  Future<void> asyncInitState() async {
    _lightingFuture = api.fetchLightingList();
  }

  Future<void> _toggleLight(LightingInfo light, bool turnOn) async {
    // If the user toggles on, we may ask for a timer or not
    int? durationSeconds = 10;
    if (turnOn) {
      durationSeconds = await _showTimerDialog(context);
      // If user cancels or closes the dialog, we do not proceed
      if (durationSeconds == null) {
        // revert the switch in UI
        setState(() {});
        return;
      }
    }

    try {
      await api.toggle(
          light: light,
          duration: Duration(seconds: durationSeconds),
          turnOn: turnOn);
      // We can optionally parse the response for updated info
      // Then re-fetch the entire lighting list
      setState(() {
        _lightingFuture = api.fetchLightingList();
      });
    } on NetworkException catch (e, _) {
      HMBToast.error(e.message);
    }
  }

  /// A simple dialog that asks the user for a duration in seconds.
  /// Returns null if canceled.
  Future<int?> _showTimerDialog(BuildContext context) async {
    final controller = TextEditingController(text: '0');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lighting Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter duration in seconds (0 for indefinite):'),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              Navigator.of(ctx).pop(val);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Lighting'),
        ),
        body: FutureBuilder<List<LightingInfo>>(
          future: _lightingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final lights = snapshot.data ?? [];
            if (lights.isEmpty) {
              return const Center(child: Text('No lighting found.'));
            }
            return ListView.builder(
              itemCount: lights.length,
              itemBuilder: (context, index) {
                final light = lights[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(light.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (light.lastOnDate != null)
                          Text('Last: ${light.lastOnDate}'),
                        if (light.timerRunning)
                          Text(
                              'Timer remaining: ${light.timerRemainingSeconds} seconds'),
                      ],
                    ),
                    trailing: Switch(
                      value: light.isOn,
                      onChanged: (value) async => _toggleLight(light, value),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
