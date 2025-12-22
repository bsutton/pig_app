import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../util/exceptions.dart';
import '../../util/hmb_theme.dart';
import 'color_ex.dart';
import 'layout/hmb_empty.dart';

class HMBButton extends StatelessWidget {
  final String label;

  final Icon? icon;

  final void Function() onPressed;

  final bool enabled;

  final Color color;

  const HMBButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
    this.color = HMBColors.buttonLabel,
  }) : icon = null;

  const HMBButton.withIcon({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.enabled = true,
    this.color = HMBColors.buttonLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: (enabled ? onPressed : null),
        label: Text(label, style: TextStyle(color: color)),
        icon: icon,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

class HMBButtonPrimary extends StatelessWidget {
  final String label;

  final VoidCallback? onPressed;

  final bool enabled;

  const HMBButtonPrimary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      disabledForegroundColor: (Colors.grey[500]!).withSafeOpacity(0.38),
      disabledBackgroundColor: (Colors.grey[500]!).withSafeOpacity(0.12),
    ),
    onPressed: (enabled ? onPressed : null),
    label: Text(label, style: const TextStyle(color: HMBColors.buttonLabel)),
    icon: const HMBEmpty(),
  );
}

class HMBButtonSecondary extends StatelessWidget {
  final String label;

  final VoidCallback? onPressed;

  const HMBButtonSecondary({
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.purple,
      disabledForegroundColor: (Colors.grey[500]!).withSafeOpacity(0.38),
      disabledBackgroundColor: (Colors.grey[500]!).withSafeOpacity(0.12),
    ),
    child: Text(label, style: const TextStyle(color: HMBColors.buttonLabel)),
  );
}

class HMBLinkButton extends StatelessWidget {
  final String label;

  final String link;

  final VoidCallback? onPressed;

  const HMBLinkButton({
    required this.label,
    required this.onPressed,
    required this.link,
    super.key,
  });

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async => _launchURL(link),
    child: Text(label, style: const TextStyle(color: Colors.blue)),
  );

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw IrrigationAppException('Could not launch $url');
    }
  }
}
