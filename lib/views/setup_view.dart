import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

class SetupView extends StatefulWidget {
  const SetupView({super.key});
  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  final _urlCtrl   = TextEditingController(text: 'http://');
  final _tokenCtrl = TextEditingController();
  final _repoCtrl  = TextEditingController();
  String _error    = '';
  bool   _loading  = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    _repoCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url   = _urlCtrl.value.text.trim();
    final token = _tokenCtrl.value.text.trim();
    final repo  = _repoCtrl.value.text.trim();

    if ([url, token, repo].any((s) => s.isEmpty)) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    setState(() { _loading = true; _error = 'Connecting...'; });

    final err = await context.read<AppState>().connect(url, token, repo);
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = 'Failed: $err'; _loading = false; });
    }
    // on success AppState.view changes → main rebuilds automatically
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color:        C.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.rocket_launch, color: C.accent, size: 28),
              const SizedBox(width: 10),
              const Text('Gitea Dashboard',
                  style: TextStyle(color: C.text, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller:  _urlCtrl,
              style:       const TextStyle(color: C.text),
              decoration:  gField('Gitea URL', hint: 'http://10.0.0.1:8094'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:   _tokenCtrl,
              obscureText:  true,
              style:        const TextStyle(color: C.text),
              decoration:   gField('Access Token'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoCtrl,
              style:      const TextStyle(color: C.text),
              decoration: gField('Repo', hint: 'arb/arbusville-scripts'),
            ),
            const SizedBox(height: 8),
            if (_error.isNotEmpty)
              Text(_error,
                  style: TextStyle(
                    color: _error.startsWith('Failed') ? C.red : C.muted,
                    fontSize: 13,
                  )),
            const SizedBox(height: 12),
            TapButton(
              text:  'Connect',
              color: C.accent,
              onTap: _loading ? null : _connect,
              horizontalMargin: 0,
            ),
          ],
        ),
      ),
    );
  }
}
