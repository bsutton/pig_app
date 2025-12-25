// lib/src/ui/end_point/end_point_configuration_screen.dart

import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/end_point_api.dart';
import '../../util/exceptions.dart';
import '../widgets/hmb_toast.dart';
import 'end_point_edit_screen.dart';

class EndPointConfigurationScreen extends StatefulWidget {
  const EndPointConfigurationScreen({super.key});

  @override
  _EndPointConfigurationScreenState createState() =>
      _EndPointConfigurationScreenState();
}

class _EndPointConfigurationScreenState
    extends State<EndPointConfigurationScreen> {
  final api = EndPointApi();
  late Future<EndPointListData> _listFuture;

  /// Local mutable list so we can reorder in‐memory
  List<EndPointData>? _endPoints;

  WeatherBureauData? selectedBureau;
  WeatherStationData? selectedStation;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _listFuture = _fetchData();
  }

  Future<EndPointListData> _fetchData() async {
    final data = await api.listEndPoints();
    // Sort by ordinal before returning
    data.endPoints.sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return data;
  }

  Future<void> _toggleEndPoint(EndPointData info, bool turnOn) async {
    try {
      await api.toggleEndPoint(endPointId: info.id!, turnOn: turnOn);
      final updated = EndPointData(
        id: info.id,
        ordinal: info.ordinal,
        name: info.name,
        activationType: info.activationType,
        gpioPinAssignment: info.gpioPinAssignment,
        endPointType: info.endPointType,
        isOn: turnOn,
      );
      _replaceEndPoint(updated);
    } on NetworkException catch (e) {
      HMBToast.error('Toggle failed: $e');
      setState(() {}); // revert UI
    }
  }

  Future<void> _deleteEndPoint(EndPointData info) async {
    // TODO(bsutton): don't allow the user to delete the endpoint
    // if it is running - do check server side.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete EndPoint?'),
        content: Text('Are you sure you want to delete  "${info.name}"?'),
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
      await api.deleteEndPoint(info.id!);
      await _refresh();
    } on NetworkException catch (e) {
      HMBToast.error('Delete failed: $e');
    }
  }

  Future<void> _refresh() async {
    _endPoints = null;
    _listFuture = _fetchData();
    setState(() {});
  }

  Future<void> _editEndPoint(EndPointData info) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EndPointEditScreen(endPointId: info.id),
      ),
    );
    if (result ?? false) {
      await _refresh();
    }
  }

  Future<void> _addEndPoint() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EndPointEditScreen()),
    );
    await _refresh();
  }

  void _onBureauSelected(WeatherBureauData? bureau) {
    setState(() {
      selectedBureau = bureau;
      selectedStation = null;
      // Possibly filter or load stations from the bureau if needed
    });
  }

  void _onStationSelected(WeatherStationData? station) {
    setState(() {
      selectedStation = station;
    });
  }

  void _replaceEndPoint(EndPointData updated) {
    setState(() {
      final list = _endPoints;
      if (list == null) {
        return;
      }
      final index = list.indexWhere((ep) => ep.id == updated.id);
      if (index == -1) {
        list.add(updated);
      } else {
        list[index] = updated;
      }
    });
  }

  /// After reordering in-memory, persist the new ordinals to the backend.
  Future<void> _persistOrder() async {
    if (_endPoints == null) {
      return;
    }
    for (var i = 0; i < _endPoints!.length; i++) {
      final ep = _endPoints![i];
      if (ep.ordinal != i) {
        final updated = EndPointData(
          id: ep.id,
          ordinal: i,
          name: ep.name,
          activationType: ep.activationType,
          gpioPinAssignment: ep.gpioPinAssignment,
          endPointType: ep.endPointType,
          isOn: ep.isOn,
        );
        try {
          // Assume save updates ordinal on the server
          await api.saveEndPointData(endPoint: updated);
          _replaceEndPoint(updated);
        } on NetworkException catch (e) {
          HMBToast.error('Failed to save order for ${ep.name}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('End Points')),
    body: FutureBuilderEx<EndPointListData>(
      future: _listFuture,
      builder: (context, data) {
        // Initialize local list once
        _endPoints ??= List.of(data!.endPoints);
        return Column(
          children: [
            _buildWeatherSelectors(data!),
            Expanded(child: _buildEndpointList()),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  onPressed: _addEndPoint,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildWeatherSelectors(EndPointListData data) => Column(
    children: [
      // Weather bureau combo
      DropdownButtonFormField<WeatherBureauData>(
        decoration: const InputDecoration(labelText: 'Weather Bureau'),
        value: selectedBureau,
        items: data.bureaus
            .map((b) => DropdownMenuItem(value: b, child: Text(b.countryName)))
            .toList(),
        onChanged: _onBureauSelected,
      ),
      // Weather station combo
      DropdownButtonFormField<WeatherStationData>(
        decoration: const InputDecoration(labelText: 'Weather Station'),
        value: selectedStation,
        items: data.stations
            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
            .toList(),
        onChanged: _onStationSelected,
      ),
    ],
  );

  Widget _buildEndpointList() {
    final list = _endPoints!;
    if (list.isEmpty) {
      return const Center(child: Text('No EndPoints configured.'));
    }
    return ReorderableListView.builder(
      key: const PageStorageKey('endPointList'),
      itemCount: list.length,
      onReorder: (oldIndex, newIndex) async {
        // Adjust for removal
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final moved = list.removeAt(oldIndex);
        list.insert(newIndex, moved);
        setState(() {});
        await _persistOrder();
      },
      itemBuilder: (context, index) {
        final ep = list[index];
        return Card(
          key: ValueKey(ep.id),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(ep.name),
            subtitle: Text('${ep.endPointType}, ${ep.gpioPinAssignment}'),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editEndPoint(ep),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEndPoint(ep),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
            trailing: Switch(
              value: ep.isOn,
              onChanged: (val) => _toggleEndPoint(ep, val),
            ),
          ),
        );
      },
    );
  }
}
