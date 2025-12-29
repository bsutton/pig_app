import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/weather_settings_api.dart';
import '../../util/exceptions.dart';
import '../widgets/wizard.dart';
import '../widgets/wizard_step.dart';

class OnboardingWizard extends StatelessWidget {
  const OnboardingWizard({
    required this.onComplete,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Wizard(
    cancelLabel: 'Not now',
    onFinished: (reason) async {
      if (reason == WizardCompletionReason.completed) {
        onComplete();
      } else {
        onDismiss();
      }
    },
    initialSteps: [
      _WelcomeStep(),
      _PrepStep(),
      _WeatherLocationStep(),
      _PinMappingStep(),
    ],
  );
}

class _WelcomeStep extends WizardStep {
  _WelcomeStep() : super(title: 'To Get Started');

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To get started, you need to define one or more End Points.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'An End Point is a Valve or Light associated with a physical '
          'Raspberry Pi GPIO Pin.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Pigation turns those endpoints into schedules and automations for '
          'irrigation and lighting.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'This short setup will help you identify each pin and create the '
          'right endpoints.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _PrepStep extends WizardStep {
  _PrepStep() : super(title: 'Before You Start');

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make sure your valves and lights are wired and powered. Keep an eye '
          'on the hardware while you pulse each pin.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Tip: You can create endpoints from the pin mapping screen using the '
          '+ button on each card.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _PinMappingStep extends WizardStep {
  _PinMappingStep() : super(title: 'Pin Mapping');

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next, you will open the pin mapping screen. Pulse each GPIO pin, '
          'observe the valve or light that activates, and assign the endpoint.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'You can adjust pulse length in the Live Manual Test panel if a '
          'longer or shorter pulse is safer for your setup.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _WeatherLocationStep extends WizardStep {
  _WeatherLocationStep() : super(title: 'Weather Location');

  final _api = WeatherSettingsApi();
  final _searchController = TextEditingController();
  List<WeatherLocationData> _results = [];
  WeatherLocationData? _selected;
  var _searchAttempted = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onEntry(
    BuildContext context,
    WizardStep priorStep,
    WizardStepTarget self, {
    required bool userOriginated,
  }) async {
    try {
      final current = await _api.getLocation();
      if (current.geohash.isNotEmpty) {
        _selected = current;
      }
      setState(() {});
    } on NetworkException {
      // Ignore when server isn't ready yet.
    } finally {
      self.confirm();
    }
  }

  @override
  Future<void> onNext(
    BuildContext context,
    WizardStepTarget intendedStep, {
    required bool userOriginated,
  }) async {
    final selected = _selected;
    if (selected != null) {
      try {
        await _api.setLocation(selected);
      } on NetworkException {
        // Allow wizard to continue even if save fails.
      }
    }
    intendedStep.confirm();
  }

  Future<void> _search(BuildContext context) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() {
      _searchAttempted = true;
    });
    try {
      final results = await _api.searchLocations(query);
      _results = results;
      setState(() {});
    } on NetworkException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weather search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your local weather location so the system can '
          'pull the correct forecasts.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search by suburb or postcode',
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(context),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _search(context),
          child: const Text('Search'),
        ),
        const SizedBox(height: 8),
        if (_results.isNotEmpty)
          SizedBox(
            height: 220,
            child: RadioGroup<WeatherLocationData>(
              groupValue: _selected,
              onChanged: (value) {
                _selected = value;
                setState(() {});
              },
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final loc = _results[index];
                  final label = '${loc.name}, ${loc.state}';
                  return RadioListTile<WeatherLocationData>(
                    value: loc,
                    title: Text(label),
                    subtitle: Text(loc.geohash),
                  );
                },
              ),
            ),
          )
        else if (_searchAttempted)
          Text(
            'No BOM data found. Try a nearby suburb or postcode.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else if (_selected != null)
          Text(
            'Selected: ${_selected!.name}, ${_selected!.state}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
  );
}
