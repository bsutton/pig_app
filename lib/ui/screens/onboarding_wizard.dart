import 'package:flutter/material.dart';

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
    initialSteps: [_WelcomeStep(), _PrepStep(), _PinMappingStep()],
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
