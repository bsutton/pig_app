import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/end_point_api.dart';
import '../../util/exceptions.dart';
import '../widgets/hmb_toast.dart';

/// A manual panel for matching valves to GPIO pin assignments.
class ValvePinMappingScreen extends StatefulWidget {
  /// Creates a screen for testing and saving valve to pin mappings.
  const ValvePinMappingScreen({super.key});

  @override
  State<ValvePinMappingScreen> createState() => _ValvePinMappingScreenState();
}

class _ValvePinMappingScreenState extends State<ValvePinMappingScreen> {
  static const _pulseDuration = Duration(milliseconds: 700);

  final _api = EndPointApi();
  late Future<EndPointListData> _listFuture;

  final _selectedPins = <int, GPIOPinAssignment>{};
  final _pulsingEndPointId = ValueNotifier<int?>(null);
  final _savingEndPointIds = ValueNotifier<Set<int>>(<int>{});

  List<EndPointData>? _endPoints;
  var _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _listFuture = _fetchData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pulsingEndPointId.dispose();
    _savingEndPointIds.dispose();
    super.dispose();
  }

  Future<EndPointListData> _fetchData() async {
    final data = await _api.listEndPoints();
    data.endPoints.sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return data;
  }

  void _ensureEndPoints(EndPointListData data) {
    if (_endPoints != null) {
      return;
    }
    _endPoints = data.endPoints.where(_isValveType).toList();
    for (final endPoint in _endPoints!) {
      final id = endPoint.id;
      if (id != null) {
        _selectedPins[id] = endPoint.gpioPinAssignment;
      }
    }
  }

  bool _isValveType(EndPointData endPoint) =>
      endPoint.endPointType == EndPointType.valve ||
      endPoint.endPointType == EndPointType.masterValve;

  Future<void> _pulseEndPoint(EndPointData endPoint) async {
    final id = endPoint.id;
    if (id == null) {
      HMBToast.error('Missing id for ${endPoint.name}.');
      return;
    }
    if (_pulsingEndPointId.value != null) {
      HMBToast.error('Another pulse is already running.');
      return;
    }

    final updated = await _savePinIfNeeded(endPoint);
    if (updated == null) {
      return;
    }

    _setPulsingId(id);
    var turnedOn = false;
    try {
      await _api.toggleEndPoint(endPointId: id, turnOn: true);
      turnedOn = true;
      await Future<void>.delayed(_pulseDuration);
    } on NetworkException catch (e, stackTrace) {
      developer.log(
        'Failed to pulse valve',
        name: 'pig_app.valve_mapping',
        error: e,
        stackTrace: stackTrace,
      );
      HMBToast.error('Pulse failed: $e');
    } finally {
      if (turnedOn) {
        try {
          await _api.toggleEndPoint(endPointId: id, turnOn: false);
        } on NetworkException catch (e, stackTrace) {
          developer.log(
            'Failed to switch valve off after pulse',
            name: 'pig_app.valve_mapping',
            error: e,
            stackTrace: stackTrace,
          );
          HMBToast.error('Failed to switch valve off: $e');
        }
      }
      _setPulsingId(null);
    }
  }

  Future<void> _savePinMapping(EndPointData endPoint) async {
    await _savePinIfNeeded(endPoint);
  }

  Future<EndPointData?> _savePinIfNeeded(EndPointData endPoint) async {
    final id = endPoint.id;
    if (id == null) {
      HMBToast.error('Missing id for ${endPoint.name}.');
      return null;
    }

    final selectedPin = _selectedPins[id] ?? endPoint.gpioPinAssignment;
    if (selectedPin.gpioPin == endPoint.gpioPinAssignment.gpioPin) {
      return endPoint;
    }

    _setSaving(id, true);
    final updated = EndPointData(
      id: endPoint.id,
      ordinal: endPoint.ordinal,
      name: endPoint.name,
      activationType: endPoint.activationType,
      gpioPinAssignment: selectedPin,
      endPointType: endPoint.endPointType,
      isOn: endPoint.isOn,
    );
    try {
      await _api.saveEndPointData(endPoint: updated);
      if (!mounted) {
        return updated;
      }
      _replaceEndPoint(updated);
      return updated;
    } on NetworkException catch (e, stackTrace) {
      developer.log(
        'Failed to save pin mapping',
        name: 'pig_app.valve_mapping',
        error: e,
        stackTrace: stackTrace,
      );
      HMBToast.error('Save failed: $e');
      return null;
    } finally {
      _setSaving(id, false);
    }
  }

  void _replaceEndPoint(EndPointData updated) {
    if (!mounted) {
      return;
    }
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
      if (updated.id != null) {
        _selectedPins[updated.id!] = updated.gpioPinAssignment;
      }
    });
  }

  void _setSaving(int id, bool saving) {
    if (_isDisposed) {
      return;
    }
    final next = Set<int>.from(_savingEndPointIds.value);
    if (saving) {
      next.add(id);
    } else {
      next.remove(id);
    }
    _savingEndPointIds.value = next;
  }

  void _setPulsingId(int? id) {
    if (_isDisposed) {
      return;
    }
    _pulsingEndPointId.value = id;
  }

  Map<int, String> _pinUsageMap(List<EndPointData> endPoints) {
    final map = <int, String>{};
    for (final endPoint in endPoints) {
      map[endPoint.gpioPinAssignment.gpioPin] = endPoint.name;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Valve Pin Mapping')),
    body: FutureBuilderEx<EndPointListData>(
      future: _listFuture,
      builder: (context, data) {
        _ensureEndPoints(data!);
        final endPoints = _endPoints!;
        final pinUsage = _pinUsageMap(data.endPoints);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MappingIntroCard(),
            Expanded(
              child: ValueListenableBuilder<int?>(
                valueListenable: _pulsingEndPointId,
                builder: (context, pulsingId, _) =>
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: _savingEndPointIds,
                      builder: (context, savingIds, _) => _ValvePinList(
                        endPoints: endPoints,
                        pinUsage: pinUsage,
                        selectedPins: _selectedPins,
                        pulsingId: pulsingId,
                        savingIds: savingIds,
                        onPinChanged: _onPinChanged,
                        onSave: _savePinMapping,
                        onPulse: _pulseEndPoint,
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    ),
  );

  void _onPinChanged(EndPointData endPoint, GPIOPinAssignment? pin) {
    final id = endPoint.id;
    if (id == null || pin == null) {
      return;
    }
    setState(() {
      _selectedPins[id] = pin;
    });
  }
}

class _MappingIntroCard extends StatelessWidget {
  const _MappingIntroCard();

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live manual test panel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a GPIO pin, pulse the valve, and confirm which valve '
            'opened. Pulse will save changes before testing.',
          ),
          const SizedBox(height: 8),
          const Text('Pulse length: 0.7 seconds.'),
        ],
      ),
    ),
  );
}

class _ValvePinList extends StatelessWidget {
  const _ValvePinList({
    required this.endPoints,
    required this.pinUsage,
    required this.selectedPins,
    required this.pulsingId,
    required this.savingIds,
    required this.onPinChanged,
    required this.onSave,
    required this.onPulse,
  });
  final List<EndPointData> endPoints;

  final Map<int, String> pinUsage;

  final Map<int, GPIOPinAssignment> selectedPins;

  final int? pulsingId;

  final Set<int> savingIds;

  final void Function(EndPointData, GPIOPinAssignment?) onPinChanged;

  final void Function(EndPointData) onSave;

  final void Function(EndPointData) onPulse;

  @override
  Widget build(BuildContext context) {
    if (endPoints.isEmpty) {
      return const Center(child: Text('No valves configured yet.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        const padding = EdgeInsets.fromLTRB(16, 0, 16, 16);
        if (isWide) {
          return GridView.builder(
            padding: padding,
            itemCount: endPoints.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 520,
              mainAxisExtent: 240,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemBuilder: (context, index) => _ValvePinCard(
              endPoint: endPoints[index],
              pinUsage: pinUsage,
              selectedPins: selectedPins,
              pulsingId: pulsingId,
              savingIds: savingIds,
              onPinChanged: onPinChanged,
              onSave: onSave,
              onPulse: onPulse,
            ),
          );
        }
        return ListView.separated(
          padding: padding,
          itemCount: endPoints.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _ValvePinCard(
            endPoint: endPoints[index],
            pinUsage: pinUsage,
            selectedPins: selectedPins,
            pulsingId: pulsingId,
            savingIds: savingIds,
            onPinChanged: onPinChanged,
            onSave: onSave,
            onPulse: onPulse,
          ),
        );
      },
    );
  }
}

class _ValvePinCard extends StatelessWidget {
  const _ValvePinCard({
    required this.endPoint,
    required this.pinUsage,
    required this.selectedPins,
    required this.pulsingId,
    required this.savingIds,
    required this.onPinChanged,
    required this.onSave,
    required this.onPulse,
  });
  final EndPointData endPoint;

  final Map<int, String> pinUsage;

  final Map<int, GPIOPinAssignment> selectedPins;

  final int? pulsingId;

  final Set<int> savingIds;

  final void Function(EndPointData, GPIOPinAssignment?) onPinChanged;

  final void Function(EndPointData) onSave;

  final void Function(EndPointData) onPulse;

  @override
  Widget build(BuildContext context) {
    final id = endPoint.id ?? -1;
    final selectedPin = selectedPins[id] ?? endPoint.gpioPinAssignment;
    final currentPin = endPoint.gpioPinAssignment;
    final isSaving = savingIds.contains(id);
    final isPulsing = pulsingId == id;
    final isBusy = isSaving || pulsingId != null;
    final hasChanged = selectedPin.gpioPin != currentPin.gpioPin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(endPoint.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${endPoint.endPointType.displayName} · '
              'Current GPIO ${currentPin.gpioPin} '
              '(Header ${currentPin.headerPin})',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GPIOPinAssignment>(
              decoration: const InputDecoration(labelText: 'Test GPIO pin'),
              initialValue: selectedPin,
              items: GPIOPinAssignment.values.map((pin) {
                final usage = pinUsage[pin.gpioPin];
                final isCurrent = pin.gpioPin == currentPin.gpioPin;
                final label = _formatPinLabel(
                  pin: pin,
                  usage: usage,
                  isCurrent: isCurrent,
                );
                return DropdownMenuItem<GPIOPinAssignment>(
                  value: pin,
                  child: Text(label),
                );
              }).toList(),
              onChanged: isBusy ? null : (pin) => onPinChanged(endPoint, pin),
            ),
            const Spacer(),
            Row(
              children: [
                OutlinedButton(
                  onPressed: (!hasChanged || isBusy)
                      ? null
                      : () => onSave(endPoint),
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : () => onPulse(endPoint),
                    icon: isPulsing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt),
                    label: Text(isPulsing ? 'Pulsing...' : 'Pulse'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPinLabel({
    required GPIOPinAssignment pin,
    required String? usage,
    required bool isCurrent,
  }) {
    final base = 'GPIO ${pin.gpioPin} (Header ${pin.headerPin})';
    if (usage == null || isCurrent) {
      return base;
    }
    return '$base · In use by $usage';
  }
}
