// end_point_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/end_point_api.dart';
import '../../util/exceptions.dart';
import '../widgets/async_state.dart';
import '../widgets/hmb_toast.dart';

class EndPointEditScreen extends StatefulWidget {
  /// If `endPointId` is null, we create a new end point; otherwise we edit an existing one.
  const EndPointEditScreen({super.key, this.endPointId});

  final int? endPointId;

  @override
  _EndPointEditScreenState createState() => _EndPointEditScreenState();
}

class _EndPointEditScreenState extends AsyncState<EndPointEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final EndPointApi api = EndPointApi();

  bool get isNew => widget.endPointId == null;

  // Local data
  int? endPointId;
  String name = '';
  GPIOPinAssignment? pinAssignment;
  PinActivationType? activationType;
  EndPointType? endPointType;

  List<GPIOPinAssignment> availablePins = [];
  List<PinActivationType> activationTypes = [];

  @override
  Future<void> asyncInitState() async {
    final editData =
        await api.fetchEndPointEditData(endPointId: widget.endPointId);
    if (editData.endPoint != null) {
      endPointId = editData.endPoint!.id;
      name = editData.endPoint!.name;
      pinAssignment = editData.endPoint!.pinAssignment;
      activationType = editData.endPoint!.activationType;
      endPointType = editData.endPoint?.endPointType;
    }
    activationTypes = editData.activationTypes;
    availablePins = editData.availablePins;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (pinAssignment == null) {
      HMBToast.error('Please select a pin');
      return;
    }
    if (activationType == null) {
      HMBToast.error('Please select an activation type');
      return;
    }
    try {
      await api.saveEndPoint(
          id: endPointId,
          name: name,
          pinAssignment: pinAssignment!,
          activationType: activationType!,
          endPointType: endPointType!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on NetworkException catch (e) {
      HMBToast.error('Save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'Add EndPoint' : 'Edit EndPoint'),
        ),
        body: FutureBuilderEx(
          future: initialised,
          builder: (ctx, _) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'EndPoint Name'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a name'
                      : null,
                  onSaved: (value) => name = value!.trim(),
                ),
                const SizedBox(height: 16),
                // Pin # dropdown
                DropdownButtonFormField<GPIOPinAssignment>(
                  decoration: const InputDecoration(labelText: 'Pin Number'),
                  value: pinAssignment,
                  items: [
                    for (final pinAssignment in availablePins)
                      DropdownMenuItem<GPIOPinAssignment>(
                        value: pinAssignment,
                        child: Text(
                            'Pin ${pinAssignment.gpioPin} (header: ${pinAssignment.headerPin})'),
                      )
                  ],
                  onChanged: (value) {
                    setState(() {
                      pinAssignment = value;
                    });
                  },
                  validator: (value) =>
                      (value == null) ? 'Please select a pin' : null,
                ),
                const SizedBox(height: 16),
                // Activation Type
                DropdownButtonFormField<PinActivationType>(
                  decoration:
                      const InputDecoration(labelText: 'Activation Type'),
                  value: activationType,
                  items: [
                    for (final type in activationTypes)
                      DropdownMenuItem<PinActivationType>(
                        value: type,
                        child: Text(type.name),
                      )
                  ],
                  onChanged: (value) {
                    setState(() {
                      activationType = value;
                    });
                  },
                  validator: (value) => (value == null)
                      ? 'Please select an activation type'
                      : null,
                ),
                const SizedBox(height: 16),
                // Activation Type
                DropdownButtonFormField<EndPointType>(
                  decoration: const InputDecoration(labelText: 'EndPoint Type'),
                  value: endPointType,
                  items: [
                    for (final type in EndPointType.values)
                      DropdownMenuItem<EndPointType>(
                        value: type,
                        child: Text(type.displayName),
                      )
                  ],
                  onChanged: (value) {
                    setState(() {
                      endPointType = value;
                    });
                  },
                  validator: (value) => (value == null)
                      ? 'Please select an End Point type'
                      : null,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text('Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
}
