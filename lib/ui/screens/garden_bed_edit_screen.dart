// garden_bed_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';

import '../../api/gardenbed.dart';
import '../../util/exceptions.dart';
import '../widgets/async_state.dart';
import '../widgets/hmb_toast.dart';

class GardenBedEditScreen extends StatefulWidget {
  // Null if new, else the ID for editing

  const GardenBedEditScreen({super.key, this.gardenBedId});
  final int? gardenBedId;

  @override
  _GardenBedEditScreenState createState() => _GardenBedEditScreenState();
}

class _GardenBedEditScreenState extends AsyncState<GardenBedEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final api = GardenBedApi();

  bool get isNew => widget.gardenBedId == null;

  // The data model we edit
  GardenBedData bedData = GardenBedData(name: '');

  List<EndPointInfo> valves = [];
  List<EndPointInfo> masterValves = [];

  final bool _allowDelete = false;

  @override
  Future<void> asyncInitState() async {
    if (widget.gardenBedId != null) {
      await api.fetchBed(widget.gardenBedId!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    try {
      await api.save(
          name: bedData.name,
          valveId: bedData.valveId!,
          masterValveId: bedData.masterValveId);
    } on NetworkException catch (e) {
      HMBToast.error('Save failed: $e');
    }
  }

  Future<void> _delete() async {
    if (bedData.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete a new GardenBed')));
      return;
    }
    // Confirm with user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete GardenBed?'),
        content: const Text('Are you sure you want to delete this bed?'),
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
      await api.deleteBed(bedData.id!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on NetworkException catch (e) {
      HMBToast.error('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'Add Garden Bed' : 'Edit Garden Bed'),
          actions: [
            if (_allowDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _delete,
              )
          ],
        ),
        body: FutureBuilderEx(
            future: initialised,
            builder: (context, _) => Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        initialValue: bedData.name,
                        decoration:
                            const InputDecoration(labelText: 'Garden Bed Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          bedData.name = value!.trim();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildValveDropdown(),
                      const SizedBox(height: 20),
                      _buildMasterValveDropdown(),
                      const SizedBox(height: 40),
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
                      ),
                    ],
                  ),
                )),
      );

  Widget _buildValveDropdown() => DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Valve'),
        value: bedData.valveId,
        items: [
          for (final val in valves)
            DropdownMenuItem<int>(
              value: val.id,
              child: Text('${val.name} (pin ${val.pinNo})'),
            )
        ],
        onChanged: (value) {
          setState(() {
            bedData.valveId = value;
          });
        },
        validator: (value) => (value == null) ? 'Please select a valve' : null,
      );

  Widget _buildMasterValveDropdown() => DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Master Valve (optional)'),
        value: bedData.masterValveId,
        items: [
          const DropdownMenuItem<int>(
            child: Text('None'),
          ),
          for (final val in masterValves)
            DropdownMenuItem<int>(
              value: val.id,
              child: Text('${val.name} (pin ${val.pinNo})'),
            )
        ],
        onChanged: (value) {
          setState(() {
            bedData.masterValveId = value;
          });
        },
      );
}
