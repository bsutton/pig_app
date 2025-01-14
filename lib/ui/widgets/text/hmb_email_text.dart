import 'package:flutter/material.dart';
import 'package:strings/strings.dart';

import '../../../ui/widgets/mail_to_icon.dart';
import '../../../util/hmb_theme.dart';
import '../../../util/plus_space.dart';

class HMBEmailText extends StatelessWidget {
  const HMBEmailText({required this.email, this.label, super.key});
  final String? label;
  final String? email;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Strings.isNotBlank(email))
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${plusSpace(label)} ${email ?? ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: HMBColors.textPrimary),
                ),
              ),
            ),
          if (Strings.isNotBlank(email))
            Align(
              alignment: Alignment.centerRight,
              child: MailToIcon(email),
            ),
        ],
      );
}
