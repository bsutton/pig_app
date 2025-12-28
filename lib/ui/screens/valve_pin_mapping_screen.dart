import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/end_point_api.dart';
import '../../util/exceptions.dart';
import '../widgets/hmb_toast.dart';
import 'end_point_edit_screen.dart';

/// A manual panel for matching valves to GPIO pin assignments.
class ValvePinMappingScreen extends StatefulWidget {
  /// Creates a screen for testing and saving valve to pin mappings.
  const ValvePinMappingScreen({super.key});

  @override
  State<ValvePinMappingScreen> createState() => _ValvePinMappingScreenState();
}

class _ValvePinMappingScreenState extends State<ValvePinMappingScreen> {
  static const _minPulseMs = 200.0;
  static const _maxPulseMs = 2000.0;
  var _pulseMs = 700.0;

  final _api = EndPointApi();
  late Future<EndPointListData> _listFuture;

  final _selectedEndPointIdsByPin = <int, int?>{};
  final _pulsingPin = ValueNotifier<int?>(null);
  final _savingPins = ValueNotifier<Set<int>>(<int>{});
  GPIOPinAssignment? _pendingSelectPin;
  EndPointListData? _lastLoadedData;
  final _hiddenPins = <int>{};
  var _hideAssignedPins = true;
  var _hideHiddenPins = true;

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
    _pulsingPin.dispose();
    _savingPins.dispose();
    super.dispose();
  }

  Future<EndPointListData> _fetchData() async {
    final data = await _api.listEndPoints();
    data.endPoints.sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return data;
  }

  void _ensureEndPoints(EndPointListData data) {
    if (identical(_lastLoadedData, data)) {
      return;
    }
    _lastLoadedData = data;
    _endPoints = data.endPoints.where(_isMappableType).toList();
    for (final pin in GPIOPinAssignment.values) {
      if (_selectedEndPointIdsByPin.containsKey(pin.gpioPin)) {
        continue;
      }
      _selectedEndPointIdsByPin[pin.gpioPin] = _endPointForPin(pin)?.id;
    }
    final pendingPin = _pendingSelectPin;
    if (pendingPin != null) {
      final endPoint = _endPointForPin(pendingPin);
      if (endPoint?.id != null) {
        _selectedEndPointIdsByPin[pendingPin.gpioPin] = endPoint!.id;
      }
      _pendingSelectPin = null;
    }
  }

  bool _isMappableType(EndPointData endPoint) =>
      endPoint.endPointType == EndPointType.valve ||
      endPoint.endPointType == EndPointType.light ||
      endPoint.endPointType == EndPointType.masterValve;

  EndPointData? _endPointForPin(GPIOPinAssignment pin) {
    final list = _endPoints;
    if (list == null) {
      return null;
    }
    for (final endPoint in list) {
      if (endPoint.gpioPinAssignment.gpioPin == pin.gpioPin) {
        return endPoint;
      }
    }
    return null;
  }

  EndPointData? _endPointForId(int id) {
    final list = _endPoints;
    if (list == null) {
      return null;
    }
    for (final endPoint in list) {
      if (endPoint.id == id) {
        return endPoint;
      }
    }
    return null;
  }

  Future<void> _pulsePin(GPIOPinAssignment pin) async {
    final selectedId = _selectedEndPointIdsByPin[pin.gpioPin];
    if (_pulsingPin.value != null) {
      HMBToast.error('Another pulse is already running.');
      return;
    }

    EndPointData? endPoint;
    var shouldSave = false;
    if (selectedId != null) {
      endPoint = _endPointForId(selectedId);
      shouldSave = true;
    } else {
      endPoint = _endPointForPin(pin);
    }
    if (endPoint == null || endPoint.id == null) {
      await _pulsePinDirectly(pin);
      return;
    }

    final updated = shouldSave
        ? await _savePinIfNeeded(endPoint, pin)
        : endPoint;
    if (updated == null) {
      return;
    }

    _setPulsingPin(pin.gpioPin);
    var turnedOn = false;
    try {
      await _api.toggleEndPoint(endPointId: updated.id!, turnOn: true);
      turnedOn = true;
      await Future<void>.delayed(Duration(milliseconds: _pulseMs.round()));
    } on NetworkException catch (e, stackTrace) {
      developer.log(
        'Failed to pulse endpoint',
        name: 'pig_app.valve_mapping',
        error: e,
        stackTrace: stackTrace,
      );
      HMBToast.error('Pulse failed: $e');
    } finally {
      if (turnedOn) {
        try {
          await _api.toggleEndPoint(endPointId: updated.id!, turnOn: false);
        } on NetworkException catch (e, stackTrace) {
          developer.log(
            'Failed to switch endpoint off after pulse',
            name: 'pig_app.valve_mapping',
            error: e,
            stackTrace: stackTrace,
          );
          HMBToast.error('Failed to switch valve off: $e');
        }
      }
      _setPulsingPin(null);
    }
  }

  Future<void> _savePinMapping(GPIOPinAssignment pin) async {
    final selectedId = _selectedEndPointIdsByPin[pin.gpioPin];
    if (selectedId == null) {
      HMBToast.error('Select an endpoint to save.');
      return;
    }
    final endPoint = _endPointForId(selectedId);
    if (endPoint == null) {
      HMBToast.error('Missing endpoint for this pin.');
      return;
    }
    await _savePinIfNeeded(endPoint, pin);
  }

  Future<void> _pulsePinDirectly(GPIOPinAssignment pin) async {
    _setPulsingPin(pin.gpioPin);
    try {
      await _api.pulsePin(pinNo: pin.gpioPin, durationMs: _pulseMs.round());
    } on NetworkException catch (e, stackTrace) {
      developer.log(
        'Failed to pulse pin directly',
        name: 'pig_app.valve_mapping',
        error: e,
        stackTrace: stackTrace,
      );
      HMBToast.error('Pulse failed: $e');
    } finally {
      _setPulsingPin(null);
    }
  }

  Future<EndPointData?> _savePinIfNeeded(
    EndPointData endPoint,
    GPIOPinAssignment selectedPin,
  ) async {
    final id = endPoint.id;
    if (id == null) {
      HMBToast.error('Missing id for ${endPoint.name}.');
      return null;
    }

    final previousPin = endPoint.gpioPinAssignment;
    if (selectedPin.gpioPin == previousPin.gpioPin) {
      return endPoint;
    }

    _setSaving(selectedPin.gpioPin, true);
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
      _replaceEndPoint(updated, previousPin: previousPin);
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
      _setSaving(selectedPin.gpioPin, false);
    }
  }

  void _replaceEndPoint(
    EndPointData updated, {
    GPIOPinAssignment? previousPin,
  }) {
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
        _selectedEndPointIdsByPin[updated.gpioPinAssignment.gpioPin] =
            updated.id;
        if (previousPin != null &&
            previousPin.gpioPin != updated.gpioPinAssignment.gpioPin) {
          final previousSelected =
              _selectedEndPointIdsByPin[previousPin.gpioPin];
          if (previousSelected == updated.id) {
            _selectedEndPointIdsByPin[previousPin.gpioPin] = null;
          }
        }
      }
    });
  }

  void _setSaving(int pin, bool saving) {
    if (_isDisposed) {
      return;
    }
    final next = Set<int>.from(_savingPins.value);
    if (saving) {
      next.add(pin);
    } else {
      next.remove(pin);
    }
    _savingPins.value = next;
  }

  void _setPulsingPin(int? pin) {
    if (_isDisposed) {
      return;
    }
    _pulsingPin.value = pin;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pin Mapping')),
    body: FutureBuilderEx<EndPointListData>(
      key: ValueKey(_listFuture),
      future: _listFuture,
      builder: (context, data) {
        _ensureEndPoints(data!);
        final endPoints = _endPoints!;
        final visiblePins = GPIOPinAssignment.values
            .where(_isPinVisible)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MappingControlsBar(
              pulseMs: _pulseMs,
              minPulseMs: _minPulseMs,
              maxPulseMs: _maxPulseMs,
              onPulseChanged: _onPulseChanged,
              hideAssignedPins: _hideAssignedPins,
              hideHiddenPins: _hideHiddenPins,
              hiddenCount: _hiddenPins.length,
              onHideAssignedChanged: _onHideAssignedChanged,
              onHideHiddenChanged: _onHideHiddenChanged,
              onResetHidden: _resetHiddenPins,
            ),
            Expanded(
              child: ValueListenableBuilder<int?>(
                valueListenable: _pulsingPin,
                builder: (context, pulsingPin, _) =>
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: _savingPins,
                      builder: (context, savingPins, _) => CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(
                            child: _MappingIntroCard(),
                          ),
                          _PinMappingSliver(
                            pins: visiblePins,
                            endPoints: endPoints,
                            selectedEndPointIdsByPin: _selectedEndPointIdsByPin,
                            pulsingPin: pulsingPin,
                            savingPins: savingPins,
                            onSelectionChanged: _onSelectionChanged,
                            onSave: _savePinMapping,
                            onPulse: _pulsePin,
                            onAddEndPoint: _addEndPoint,
                            onHidePin: _hidePin,
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    ),
  );

  void _onSelectionChanged(GPIOPinAssignment pin, int? endPointId) {
    setState(() {
      if (endPointId == null) {
        _selectedEndPointIdsByPin[pin.gpioPin] = null;
        return;
      }
      _selectedEndPointIdsByPin[pin.gpioPin] = endPointId;
      for (final entry in _selectedEndPointIdsByPin.entries) {
        if (entry.key != pin.gpioPin && entry.value == endPointId) {
          _selectedEndPointIdsByPin[entry.key] = null;
        }
      }
    });
  }

  void _onPulseChanged(double value) {
    setState(() {
      _pulseMs = value;
    });
  }

  void _onHideAssignedChanged(bool value) {
    setState(() {
      _hideAssignedPins = value;
    });
  }

  void _onHideHiddenChanged(bool value) {
    setState(() {
      _hideHiddenPins = value;
    });
  }

  void _resetHiddenPins() {
    setState(_hiddenPins.clear);
  }

  void _hidePin(GPIOPinAssignment pin) {
    setState(() {
      _hiddenPins.add(pin.gpioPin);
    });
  }

  bool _isPinVisible(GPIOPinAssignment pin) {
    if (_hideHiddenPins && _hiddenPins.contains(pin.gpioPin)) {
      return false;
    }
    if (_hideAssignedPins && _endPointForPin(pin) != null) {
      return false;
    }
    return true;
  }

  Future<void> _addEndPoint(GPIOPinAssignment pin) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EndPointEditScreen(initialPinAssignment: pin),
      ),
    );
    if (!mounted || created != true) {
      return;
    }
    setState(() {
      _pendingSelectPin = pin;
      _endPoints = null;
      _lastLoadedData = null;
      _selectedEndPointIdsByPin.clear();
      _listFuture = _fetchData();
    });
  }
}

class _MappingIntroCard extends StatelessWidget {
  const _MappingIntroCard();

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                'Pulse each GPIO pin, watch which valve or light activates, '
                'and assign the matching endpoint. Pulse will save the '
                'selection before testing.',
              ),
            ],
          ),
        ),
      );
}

class _MappingControlsBar extends StatelessWidget {
  const _MappingControlsBar({
    required this.pulseMs,
    required this.minPulseMs,
    required this.maxPulseMs,
    required this.onPulseChanged,
    required this.hideAssignedPins,
    required this.hideHiddenPins,
    required this.hiddenCount,
    required this.onHideAssignedChanged,
    required this.onHideHiddenChanged,
    required this.onResetHidden,
  });

  final double pulseMs;
  final double minPulseMs;
  final double maxPulseMs;
  final ValueChanged<double> onPulseChanged;
  final bool hideAssignedPins;
  final bool hideHiddenPins;
  final int hiddenCount;
  final ValueChanged<bool> onHideAssignedChanged;
  final ValueChanged<bool> onHideHiddenChanged;
  final VoidCallback onResetHidden;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pulse length: ${(pulseMs / 1000).toStringAsFixed(1)} seconds.',
            ),
            Slider(
              value: pulseMs,
              min: minPulseMs,
              max: maxPulseMs,
              divisions: 18,
              label: '${pulseMs.round()} ms',
              onChanged: onPulseChanged,
            ),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterToggle(
                  label: 'Hide assigned pins',
                  value: hideAssignedPins,
                  onChanged: onHideAssignedChanged,
                ),
                _FilterToggle(
                  label: 'Hide hidden pins',
                  value: hideHiddenPins,
                  onChanged: onHideHiddenChanged,
                ),
                if (hiddenCount > 0)
                  Text('Hidden: $hiddenCount', style: subtitleStyle),
                TextButton(
                  onPressed: hiddenCount == 0 ? null : onResetHidden,
                  child: const Text('Reset hidden'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(value: value, onChanged: onChanged),
      Text(label),
    ],
  );
}

class _PinMappingSliver extends StatelessWidget {
  const _PinMappingSliver({
    required this.pins,
    required this.endPoints,
    required this.selectedEndPointIdsByPin,
    required this.pulsingPin,
    required this.savingPins,
    required this.onSelectionChanged,
    required this.onSave,
    required this.onPulse,
    required this.onAddEndPoint,
    required this.onHidePin,
  });

  final List<GPIOPinAssignment> pins;

  final List<EndPointData> endPoints;

  final Map<int, int?> selectedEndPointIdsByPin;

  final int? pulsingPin;

  final Set<int> savingPins;

  final void Function(GPIOPinAssignment, int?) onSelectionChanged;

  final void Function(GPIOPinAssignment) onSave;

  final void Function(GPIOPinAssignment) onPulse;

  final void Function(GPIOPinAssignment) onAddEndPoint;

  final void Function(GPIOPinAssignment) onHidePin;

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No pins match the current filters.')),
      );
    }
    final selectedPinsByEndPoint = _selectedPinsByEndPoint(
      selectedEndPointIdsByPin,
    );
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.crossAxisExtent >= 900;
        const padding = EdgeInsets.fromLTRB(16, 0, 16, 16);
        if (isWide) {
          return SliverPadding(
            padding: padding,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 520,
                mainAxisExtent: 240,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PinMappingCard(
                  pin: pins[index],
                  endPoints: endPoints,
                  selectedEndPointIdsByPin: selectedEndPointIdsByPin,
                  selectedPinsByEndPoint: selectedPinsByEndPoint,
                  pulsingPin: pulsingPin,
                  savingPins: savingPins,
                  onSelectionChanged: onSelectionChanged,
                  onSave: onSave,
                  onPulse: onPulse,
                  onAddEndPoint: onAddEndPoint,
                  onHidePin: onHidePin,
                ),
                childCount: pins.length,
              ),
            ),
          );
        }
        return SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final pinIndex = index ~/ 2;
                if (index.isOdd) {
                  return const SizedBox(height: 16);
                }
                return _PinMappingCard(
                  pin: pins[pinIndex],
                  endPoints: endPoints,
                  selectedEndPointIdsByPin: selectedEndPointIdsByPin,
                  selectedPinsByEndPoint: selectedPinsByEndPoint,
                  pulsingPin: pulsingPin,
                  savingPins: savingPins,
                  onSelectionChanged: onSelectionChanged,
                  onSave: onSave,
                  onPulse: onPulse,
                  onAddEndPoint: onAddEndPoint,
                  onHidePin: onHidePin,
                );
              },
              childCount: pins.length * 2 - 1,
            ),
          ),
        );
      },
    );
  }

  static Map<int, GPIOPinAssignment> _selectedPinsByEndPoint(
    Map<int, int?> selectedEndPointIdsByPin,
  ) {
    final map = <int, GPIOPinAssignment>{};
    for (final entry in selectedEndPointIdsByPin.entries) {
      final endPointId = entry.value;
      if (endPointId == null) {
        continue;
      }
      map[endPointId] = GPIOPinAssignment.getByPinNo(entry.key);
    }
    return map;
  }
}

class _PinMappingCard extends StatelessWidget {
  const _PinMappingCard({
    required this.pin,
    required this.endPoints,
    required this.selectedEndPointIdsByPin,
    required this.selectedPinsByEndPoint,
    required this.pulsingPin,
    required this.savingPins,
    required this.onSelectionChanged,
    required this.onSave,
    required this.onPulse,
    required this.onAddEndPoint,
    required this.onHidePin,
  });

  final GPIOPinAssignment pin;

  final List<EndPointData> endPoints;

  final Map<int, int?> selectedEndPointIdsByPin;

  final Map<int, GPIOPinAssignment> selectedPinsByEndPoint;

  final int? pulsingPin;

  final Set<int> savingPins;

  final void Function(GPIOPinAssignment, int?) onSelectionChanged;

  final void Function(GPIOPinAssignment) onSave;

  final void Function(GPIOPinAssignment) onPulse;

  final void Function(GPIOPinAssignment) onAddEndPoint;

  final void Function(GPIOPinAssignment) onHidePin;

  @override
  Widget build(BuildContext context) {
    final selectedEndPointId = selectedEndPointIdsByPin[pin.gpioPin];
    final currentEndPoint = _endPointForPin(endPoints, pin);
    final selectedEndPoint =
        selectedEndPointId == null || selectedEndPointId == -1
        ? null
        : _endPointForId(endPoints, selectedEndPointId);
    final isSaving = savingPins.contains(pin.gpioPin);
    final isPulsing = pulsingPin == pin.gpioPin;
    final isBusy = isSaving || pulsingPin != null;
    final hasChanged =
        selectedEndPointId != null && selectedEndPointId != currentEndPoint?.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GPIO ${pin.gpioPin}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('GPIO ${pin.gpioPin} (Header ${pin.headerPin})'),
            const SizedBox(height: 4),
            Text(_currentAssignmentText(currentEndPoint)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(labelText: 'Assign endpoint'),
              initialValue: selectedEndPointId,
              items: [
                const DropdownMenuItem<int?>(child: Text('Unassigned')),
                for (final endPoint in endPoints)
                  if (endPoint.id != null)
                    DropdownMenuItem<int?>(
                      value: endPoint.id,
                      child: Text(
                        _formatEndPointLabel(
                          endPoint: endPoint,
                          pin: pin,
                          selectedPin: selectedPinsByEndPoint[endPoint.id!],
                        ),
                      ),
                    ),
              ],
              onChanged: isBusy
                  ? null
                  : (endPointId) => onSelectionChanged(pin, endPointId),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isBusy ? null : () => onAddEndPoint(pin),
                icon: const Icon(Icons.add),
                label: const Text('Add endpoint for this pin'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isBusy ? null : () => onHidePin(pin),
                icon: const Icon(Icons.visibility_off),
                label: const Text('Hide this pin'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: (!hasChanged || isBusy || selectedEndPoint == null)
                      ? null
                      : () => onSave(pin),
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
                    onPressed: isBusy ? null : () => onPulse(pin),
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

  static EndPointData? _endPointForPin(
    List<EndPointData> endPoints,
    GPIOPinAssignment pin,
  ) {
    for (final endPoint in endPoints) {
      if (endPoint.gpioPinAssignment.gpioPin == pin.gpioPin) {
        return endPoint;
      }
    }
    return null;
  }

  static EndPointData? _endPointForId(List<EndPointData> endPoints, int id) {
    for (final endPoint in endPoints) {
      if (endPoint.id == id) {
        return endPoint;
      }
    }
    return null;
  }

  static String _currentAssignmentText(EndPointData? endPoint) {
    if (endPoint == null) {
      return 'Currently unassigned.';
    }
    return 'Currently ${endPoint.name} '
        '(${endPoint.endPointType.displayName}).';
  }

  static String _formatEndPointLabel({
    required EndPointData endPoint,
    required GPIOPinAssignment pin,
    required GPIOPinAssignment? selectedPin,
  }) {
    final base =
        '${endPoint.name} '
        '(${endPoint.endPointType.displayName})';
    final usedPin = selectedPin ?? endPoint.gpioPinAssignment;
    if (usedPin.gpioPin == pin.gpioPin) {
      return base;
    }
    return '$base · In use by GPIO ${usedPin.gpioPin}';
  }
}
