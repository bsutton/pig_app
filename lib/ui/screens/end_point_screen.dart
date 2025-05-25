// end_point_configuration_screen.dart
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

  WeatherBureauInfo? selectedBureau;
  WeatherStationInfo? selectedStation;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _listFuture = _fetchData();
  }

  Future<EndPointListData> _fetchData() async => api.listEndPoints();

  Future<void> _toggleEndPoint(EndPointInfo info, bool turnOn) async {
    // Optional: block if a valve is running, but you'd do that server side
    try {
      await api.toggleEndPoint(endPointId: info.id!, turnOn: turnOn);
      setState(() {
        _listFuture = _fetchData(); // refresh
      });
    } on NetworkException catch (e) {
      HMBToast.error('Toggle failed: $e');
      // revert the switch in UI
      setState(() {});
    }
  }

  Future<void> _deleteEndPoint(EndPointInfo info) async {
    // If we want to check "any valve running", do it server side
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete EndPoint?'),
        content: Text('Are you sure you want to delete "${info.name}"?'),
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
    _listFuture = _fetchData();
    setState(() {});
  }

  Future<void> _editEndPoint(EndPointInfo info) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute<bool>(
          builder: (ctx) => EndPointEditScreen(endPointId: info.id),
        ));
    if (result ?? false) {
      await _refresh();
    }
  }

  Future<void> _addEndPoint() async {
    await Navigator.push(
        context,
        MaterialPageRoute<bool>(
          builder: (ctx) => const EndPointEditScreen(),
        ));
    await _refresh();
  }

  void _onBureauSelected(WeatherBureauInfo? bureau) {
    setState(() {
      selectedBureau = bureau;
      selectedStation = null;
      // Possibly filter or load stations from the bureau if needed
    });
  }

  void _onStationSelected(WeatherStationInfo? station) {
    setState(() {
      selectedStation = station;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('End Points'),
        ),
        body: FutureBuilderEx(
          future: _listFuture,
          builder: (context, data) => Column(
            children: [
              _buildWeatherSelectors(data!),
              Expanded(child: _buildEndpointList(data)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: _addEndPoint,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              )
            ],
          ),
        ),
      );

  Widget _buildWeatherSelectors(EndPointListData data) => Column(
        children: [
          // Weather bureau combo
          DropdownButtonFormField<WeatherBureauInfo>(
            decoration: const InputDecoration(labelText: 'Weather Bureau'),
            value: selectedBureau,
            items: data.bureaus
                .map((b) => DropdownMenuItem<WeatherBureauInfo>(
                      value: b,
                      child: Text(b.countryName),
                    ))
                .toList(),
            onChanged: _onBureauSelected,
          ),
          // Weather station combo
          DropdownButtonFormField<WeatherStationInfo>(
            decoration: const InputDecoration(labelText: 'Weather Station'),
            value: selectedStation,
            items: data.stations
                .map((s) => DropdownMenuItem<WeatherStationInfo>(
                      value: s,
                      child: Text(s.name),
                    ))
                .toList(),
            onChanged: _onStationSelected,
          ),
        ],
      );

  Widget _buildEndpointList(EndPointListData data) {
    if (data.endPoints.isEmpty) {
      return const Center(child: Text('No EndPoints configured.'));
    }
    return ListView.builder(
      itemCount: data.endPoints.length,
      itemBuilder: (context, index) {
        final ep = data.endPoints[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(ep.name),
            subtitle: Text('${ep.endPointType}, ${ep.pinAssignment}'),
            trailing: Switch(
              value: ep.isOn,
              onChanged: (val) => _toggleEndPoint(ep, val),
            ),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
