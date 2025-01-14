import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';

import '../../api/lighting.dart';

class HMBStatusBar extends StatelessWidget {
  const HMBStatusBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.purpleAccent,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: FutureBuilderEx(
                // ignore: discarded_futures
                future: LightingApi().fetchLightingList(),
                builder: (context, lightingList) => const Text(
                  'Show what is being watered',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}
