// garden_bed_configuration_screen.dart
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';

import '../../api/gardenbed.dart';
import '../../util/exceptions.dart';
import '../widgets/async_state.dart';
import 'garden_bed_edit_screen.dart';

class GardenBedConfigurationScreen extends StatefulWidget {
  const GardenBedConfigurationScreen({super.key});

  @override
  _GardenBedConfigurationScreenState createState() =>
      _GardenBedConfigurationScreenState();
}

class _GardenBedConfigurationScreenState
    extends AsyncState<GardenBedConfigurationScreen> {
  late Future<List<GardenBedInfo>> _bedsFuture;

  final api = GardenBedApi();

  @override
  Future<void> asyncInitState() async {
    _bedsFuture = api.fetchGardenBeds();
  }

  Future<void> _onAddClicked() async {
    // Navigate to edit screen with a null bed
    final result = await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (ctx) => const GardenBedEditScreen()),
    );
    if (result ?? false) {
      _refresh();
    }
  }

  Future<void> _onEditClicked(GardenBedInfo bed) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute<bool>(
          builder: (ctx) => GardenBedEditScreen(gardenBedId: bed.id)),
    );
    if (result ?? false) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Garden Beds'),
        ),
        body: FutureBuilderEx<List<GardenBedInfo>>(
          // ignore: discarded_futures
          future: _bedsFuture,
          builder: (context, beds) {
            if (beds!.isEmpty) {
              return const Center(child: Text('No garden beds found.'));
            }
            return ListView.builder(
              itemCount: beds.length,
              itemBuilder: (context, index) {
                final bed = beds[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(bed.name),
                    subtitle: Row(
                      children: [
                        Text('ID: ${bed.id}'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await api.deleteBed(bed.id);
                              _refresh();
                            } on NetworkException catch (e, _) {
                              _refresh();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                    trailing: Switch(
                      value: bed.isOn,
                      onChanged: (on) async {
                        await api.toggleBed(bed: bed, turnOn: on);
                        _refresh();
                      },
                    ),
                    onTap: () async => _onEditClicked(bed),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAddClicked,
          child: const Icon(Icons.add),
        ),
      );

  void _refresh() {
    setState(() {
      // ignore: discarded_futures
      _bedsFuture = api.fetchGardenBeds();
    });
  }
}
