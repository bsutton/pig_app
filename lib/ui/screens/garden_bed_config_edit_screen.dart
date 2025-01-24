// garden_bed_edit_screen.dart
import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';
import '../../util/exceptions.dart';
import '../../util/list_ex.dart';
import '../widgets/hmb_toast.dart';

class GardenBedEditScreen extends StatefulWidget {
  /// If `gardenBedId` is null, we create a new bed; otherwise we edit an existing bed.
  const GardenBedEditScreen({super.key, this.gardenBedId});

  final int? gardenBedId;

  @override
  _GardenBedEditScreenState createState() => _GardenBedEditScreenState();
}

class _GardenBedEditScreenState extends DeferredState<GardenBedEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final api = GardenBedApi();

  bool get isNew => widget.gardenBedId == null;

  /// The data model for the currently edited bed.
  late final GardenBedListData bedData;
  late final GardenBedData bed;

  @override
  Future<void> asyncInitState() async {
    bedData = await api.fetchBedEditData(widget.gardenBedId);
    bed = bedData.beds.firstOrNull ?? GardenBedData();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    try {
      await api.save(bed);

      if (mounted) {
        Navigator.of(context).pop(true); // Indicate success
      }
    } on NetworkException catch (e) {
      HMBToast.error('Save failed: $e');
    }
  }

  Future<void> _delete() async {
    if (bed.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete a new GardenBed')),
      );
      return;
    }
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
      await api.deleteBed(bed.id!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on NetworkException catch (e) {
      HMBToast.error('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => DeferredBuilder(this,
      builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(isNew ? 'Add Garden Bed' : 'Edit Garden Bed'),
              actions: [
                if (bed.allowDelete)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _delete,
                  ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Garden Bed Name
                  TextFormField(
                    initialValue: bed.name,
                    decoration:
                        const InputDecoration(labelText: 'Garden Bed Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      bed.name = value!.trim();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Garden Bed Description
                  TextFormField(
                    initialValue: bed.description,
                    decoration: const InputDecoration(
                        labelText: 'Garden Bed Description'),
                    maxLines: 2,
                    onSaved: (value) {
                      bed.description = value?.trim();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Valve
                  _buildValveDropdown(),

                  const SizedBox(height: 16),

                  // Master Valve
                  _buildMasterValveDropdown(),

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
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ));

  Widget _buildValveDropdown() => DropdownButtonFormField<EndPointInfo>(
        decoration: const InputDecoration(labelText: 'Valve'),
        value:
            bedData.valves.firstWhereOrNull((value) => value.id == bed.valveId),
        items: [
          for (final val in bedData.valves)
            DropdownMenuItem<EndPointInfo>(
              value: val,
              child: Text(
                  '${val.name} (GPIO Pin ${val.pinAssignment.gpioPin} (Header: ${val.pinAssignment.headerPin}))'),
            )
        ],
        onChanged: (value) {
          setState(() {
            bed.valveId = value?.id;
          });
        },
        validator: (value) => (value == null) ? 'Please select a valve' : null,
      );

  Widget _buildMasterValveDropdown() => DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Master Valve (optional)'),
        value: bed.masterValveId,
        items: [
          const DropdownMenuItem<int>(
            child: Text('None'),
          ),
          for (final val in bedData.masterValves)
            DropdownMenuItem<int>(
              value: val.id,
              child: Text(
                  '${val.name} (GPIO Pin ${val.pinAssignment.gpioPin} (Header: ${val.pinAssignment.headerPin}))'),
            )
        ],
        onChanged: (value) {
          setState(() {
            bed.masterValveId = value;
          });
        },
      );
}
