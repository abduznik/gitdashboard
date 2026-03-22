import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

class RunFormView extends StatefulWidget {
  const RunFormView({super.key});
  @override
  State<RunFormView> createState() => _RunFormViewState();
}

class _RunFormViewState extends State<RunFormView> {
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, String>                _dropValues = {};
  String _status = '';
  bool   _loading = false;

  @override
  void dispose() {
    for (final c in _textCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _run(AppState state) async {
    setState(() { _loading = true; _status = 'Triggering...'; });

    final inputs = <String, String>{};
    final wfInputs = (state.activeWf?['_inputs'] as Map?) ?? {};

    for (final entry in wfInputs.entries) {
      final name  = entry.key.toString();
      final itype = ((entry.value as Map?)?['type'] ?? 'string').toString();
      if (itype == 'boolean') {
        inputs[name] = _dropValues[name] ?? 'false';
      } else {
        inputs[name] = _textCtrls[name]?.text ?? '';
      }
    }

    final err = await state.triggerWorkflow(inputs);
    if (!mounted) return;
    if (err != null) {
      setState(() { _status = 'Error: $err'; _loading = false; });
    } else {
      setState(() { _status = 'Triggered!'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final wf       = state.activeWf;
    if (wf == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => state.setView(AppView.workflows));
      return const SizedBox();
    }

    final wfInputs = (wf['_inputs'] as Map?) ?? {};

    // Initialise controllers for new inputs
    for (final entry in wfInputs.entries) {
      final name    = entry.key.toString();
      final idef    = (entry.value as Map?) ?? {};
      final itype   = (idef['type'] ?? 'string').toString();
      final defVal  = (idef['default'] ?? '').toString();

      if (itype == 'boolean') {
        _dropValues.putIfAbsent(name, () =>
            (defVal.toLowerCase() == 'true') ? 'true' : 'false');
      } else {
        _textCtrls.putIfAbsent(name, () => TextEditingController(text: defVal));
      }
    }

    return Column(
      children: [
        TopBar(
          title:   wf['name'] ?? 'Run Workflow',
          leading: IconButton(
            icon:      const Icon(Icons.arrow_back, color: C.muted),
            onPressed: () => state.setView(AppView.workflows),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SectionHeader('INPUTS'),
              if (wfInputs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child:   Text('No inputs required — ready to run.',
                      style: TextStyle(color: C.muted, fontSize: 13)),
                )
              else
                ...wfInputs.entries.map((entry) {
                  final name  = entry.key.toString();
                  final idef  = (entry.value as Map?) ?? {};
                  final desc  = (idef['description'] ?? name).toString();
                  final req   = idef['required'] == true;
                  final itype = (idef['type'] ?? 'string').toString();
                  final label = '$desc${req ? ' *' : ''}';
                  final isLong = name.toLowerCase().contains('url') ||
                      name.toLowerCase().contains('list') ||
                      itype == 'textarea';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: itype == 'boolean'
                        ? DropdownButtonFormField<String>(
                            value:         _dropValues[name],
                            dropdownColor: C.surface2,
                            style:         const TextStyle(color: C.text),
                            decoration:    gField(label),
                            items: ['true', 'false'].map((v) =>
                                DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _dropValues[name] = v);
                            },
                          )
                        : TextField(
                            controller: _textCtrls[name],
                            style:      const TextStyle(color: C.text),
                            maxLines:   isLong ? 6 : 1,
                            minLines:   isLong ? 4 : 1,
                            decoration: gField(label),
                          ),
                  );
                }),

              const SizedBox(height: 12),
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_status,
                      style: TextStyle(
                        color:    _status.startsWith('Error') ? C.red : C.muted,
                        fontSize: 13,
                      )),
                ),
              const SizedBox(height: 8),
              TapButton(
                text:  'Run Workflow',
                color: C.green,
                onTap: _loading ? null : () => _run(state),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
