import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/auth_api.dart';
import '../../util/exceptions.dart';
import '../../util/server_settings.dart';
import '../widgets/hmb_toast.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LoginForm();
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _api = AuthApi();
  var _isBusy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await _api.login(_passwordController.text);
      if (!mounted) {
        return;
      }
      context.go('/overview');
    } on NetworkException catch (_) {
      HMBToast.error('Login failed. Check server URL.');
    } on IrrigationAppException catch (e) {
      HMBToast.error(e.message);
    } on Exception catch (e) {
      HMBToast.error('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _promptServerUrl() async {
    final controller = TextEditingController(
      text:
          ServerSettings.serverUrlOverride ??
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
    HMBToast.info('Server URL updated.');
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Form(
        key: _formKey,
        child: AbsorbPointer(
          absorbing: _isBusy,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter password' : null,
                  onFieldSubmitted: (_) async {
                    if (_isBusy) {
                      return;
                    }
                    await _login();
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isBusy ? null : _login,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isBusy ? 'Logging in...' : 'Login'),
                      if (_isBusy) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _promptServerUrl,
                  icon: const Icon(Icons.link),
                  label: const Text('Set server URL'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
