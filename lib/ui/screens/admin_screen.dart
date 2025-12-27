import 'package:flutter/material.dart';

import '../../util/server_settings.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(
      text: ServerSettings.serverUrlOverride ?? '',
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ServerSettings.setServerUrlOverride(_serverUrlController.text);
    final wsUrl =
        ServerSettings.toWebSocketUrl(ServerSettings.serverUrlOverride);
    await ServerSettings.setWebSocketUrlOverride(wsUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL saved')),
      );
    }
  }

  Future<void> _clear() async {
    _serverUrlController.text = '';
    await ServerSettings.setServerUrlOverride(null);
    await ServerSettings.setWebSocketUrlOverride(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server Connection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverUrlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://your-server',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _clear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Leave blank to use environment defaults or the current origin '
            'for web builds.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}
