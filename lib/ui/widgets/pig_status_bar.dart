import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:go_router/go_router.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';
import '../../api/notification_manager.dart';
import '../../util/ansi_color.dart';
import '../../util/auth_store.dart';
import '../../util/server_settings.dart';

class PIGStatusBar extends StatefulWidget {
  const PIGStatusBar({super.key});

  @override
  State<PIGStatusBar> createState() => _PIGStatusBarState();
}

class _PIGStatusBarState extends State<PIGStatusBar> {
  late final NoticeListener noticeListener;

  @override
  void initState() {
    super.initState();
    print(orange('starting notification listener'));
    noticeListener = NotificationManager().addListener((notice) async {
      print('recieved notice $notice');
      await _handleNotice(notice);
    });
  }

  @override
  void dispose() {
    print(orange('removing notification listener'));
    NotificationManager().removeListener(noticeListener);
    super.dispose();
  }

  var running = <int, Notice>{};

  Future<void> _handleNotice(Notice notice) async {
    print('_handleNotice');
    if (notice.featureType != FeatureType.gardenBed) {
      return;
    }
    switch (notice.noticeType) {
      case NoticeType.start:
        running[notice.featureId] = notice;
      case NoticeType.stop:
        running.remove(notice.featureId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.purpleAccent,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: _shouldShowStatus(context)
                  ? FutureBuilderEx(
                      // ignore: discarded_futures
                      future: GardenBedApi().fetchGardenBeds(),
                      errorBuilder: (context, error) => Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          border: Border.all(color: Colors.orange.shade700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Network error: $error',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Set server URL',
                              icon: const Icon(Icons.link, color: Colors.black),
                              onPressed: () => _promptServerUrl(context),
                            ),
                            IconButton(
                              tooltip: 'Reload',
                              icon:
                                  const Icon(Icons.refresh, color: Colors.black),
                              onPressed: () => _reloadCurrentRoute(context),
                            ),
                          ],
                        ),
                      ),
                      builder: (context, bedList) => Text(
                        running.isEmpty
                            ? ''
                            : 'Running: '
                                '${running.entries.first.value.description}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );

  bool _shouldShowStatus(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final isPublicRoute = location.startsWith('/public');
    return AuthStore.isLoggedIn && !isPublicRoute;
  }

  void _reloadCurrentRoute(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    if (location.isEmpty) {
      return;
    }
    router.go(location);
  }

  Future<void> _promptServerUrl(BuildContext context) async {
    final controller = TextEditingController(
      text: ServerSettings.serverUrlOverride ??
          ServerSettings.webFallbackServerUrl() ??
          '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'https://your-server',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) {
      return;
    }
    await ServerSettings.setServerUrlOverride(result);
    final wsUrl = ServerSettings.toWebSocketUrl(result);
    await ServerSettings.setWebSocketUrlOverride(wsUrl);
    if (context.mounted) {
      _reloadCurrentRoute(context);
    }
  }
}
