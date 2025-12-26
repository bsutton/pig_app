import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../nav/onboarding_state.dart';
import 'onboarding_wizard.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => OnboardingWizard(
    onComplete: () {
      dismissOnboarding();
      context.go('/config/valve_pin_mapping');
    },
    onDismiss: () {
      dismissOnboarding();
      context.go('/overview');
    },
  );
}
