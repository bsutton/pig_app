// garden_bed_configuration_screen.dart
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';
import '../../util/exceptions.dart';
import '../../util/list_ex.dart';
import '../widgets/async_state.dart';
import '../widgets/hmb_toast.dart';
import 'garden_bed_edit_screen.dart';

class GardenBedConfigurationScreen extends StatefulWidget {
  const GardenBedConfigurationScreen({super.key});

  @override
  _GardenBedConfigurationScreenState createState() =>
      _GardenBedConfigurationScreenState();
}

class _GardenBedConfigurationScreenState
    extends AsyncState<GardenBedConfigurationScreen> {
  late GardenBedListData bedData;
  late List<GardenBedData> beds;

  final api = GardenBedApi();

  late bool noValves;

  @override
  Future<void> asyncInitState() async {
    await _refresh();
  }

  Future<void> _onAddClicked() async {
    if (noValves) {
      HMBToast.error(
          'You must add a EndPoint Valve before you can add a Garden Bed');
      return;
    }
    // Navigate to edit screen with a null bed
    final result = await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (ctx) => const GardenBedEditScreen()),
    );
    if (result ?? false) {
      await _refresh();
    }
  }

  Future<void> _onEditClicked(GardenBedData bed) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute<bool>(
          builder: (ctx) => GardenBedEditScreen(gardenBedId: bed.id)),
    );
    if (result ?? false) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Garden Beds'),
        ),
        body: FutureBuilderEx<void>(
          // ignore: discarded_futures
          future: initialised,
          builder: (context, listData) {
            if (beds.isEmpty) {
              return const Center(child: Text('No garden beds found.'));
            }
            return ListView.builder(
              itemCount: beds.length,
              itemBuilder: (context, index) {
                final bed = beds[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(bed.name!),
                    subtitle: Row(
                      children: [
                        Text('Valve: ${_getValveName(bedData, bed)}'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await api.deleteBed(bed.id!);
                              await _refresh();
                            } on NetworkException catch (e, _) {
                              await _refresh();
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
                        await _refresh();
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

  String _getValveName(GardenBedListData data, GardenBedData bed) =>
      data.valves.firstWhereOrNull((valve) => valve.id == bed.valveId)?.name ??
      '';

  Future<void> _refresh() async {
    bedData = await api.fetchGardenBeds();

    beds = bedData.beds;
    noValves = bedData.valves.isEmpty;
    setState(() {});
  }
}
