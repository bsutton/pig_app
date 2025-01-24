// garden_bed_configuration_screen.dart
import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';
import '../../util/exceptions.dart';
import '../../util/list_ex.dart';
import '../widgets/hmb_toast.dart';
import 'garden_bed_config_edit_screen.dart';

class GardenBedConfigurationScreen extends StatefulWidget {
  const GardenBedConfigurationScreen({super.key});

  @override
  _GardenBedConfigurationScreenState createState() =>
      _GardenBedConfigurationScreenState();
}

class _GardenBedConfigurationScreenState
    extends DeferredState<GardenBedConfigurationScreen> {
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
        body: DeferredBuilder(
          this,
          builder: (context) {
            if (beds.isEmpty) {
              return const Center(child: Text('No garden beds found.'));
            }
            return _buildGardenList(bedData);
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAddClicked,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildGardenList(GardenBedListData data) {
    if (data.beds.isEmpty) {
      return const Center(child: Text('No Garden Beds configured.'));
    }
    return ListView.builder(
      itemCount: data.beds.length,
      itemBuilder: (context, index) {
        final bed = data.beds[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(bed.name!),
            subtitle: Text('Valve: ${_getValveName(bedData, bed)}'),
            trailing: Switch(
              value: bed.isOn,
              onChanged: (val) async {
                await api.toggleBed(bed: bed, turnOn: val);
                await _refresh();
              },
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async => _onEditClicked(bed),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async => _onDeleteClicked(bed),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeleteClicked(GardenBedData bed) async {
    // If we want to check "any valve running", do it server side
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Garden Bed?'),
        content: Text('Are you sure you want to delete "${bed.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await api.deleteBed(bed.id!);
      await _refresh();
    } on NetworkException catch (e) {
      HMBToast.error('Delete failed: $e');
    }
  }

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
