import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/gitea.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

class RunDetailView extends StatelessWidget {
  const RunDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final run   = state.selectedRun ?? {};

    final s     = (run['status']     as String? ?? 'unknown').toLowerCase();
    final c     = (run['conclusion'] as String? ?? '').toLowerCase();
    final key   = c.isNotEmpty ? c : s;
    final color = statusColor(key);
    final icon  = statusIcon(key);
    final name  = wfDisplayName(run);

    return Column(
      children: [
        TopBar(
          leading: IconButton(
            icon:      const Icon(Icons.arrow_back, color: C.muted),
            onPressed: () => state.setView(AppView.runs),
          ),
          title: name,
          actions: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            IconButton(
              icon:      const Icon(Icons.refresh, color: C.muted),
              onPressed: () => state.reloadRunDetail(),
            ),
          ],
        ),
        Expanded(
          child: Container(
            width:   double.infinity,
            color:   C.bg,
            padding: const EdgeInsets.all(16),
            child:   SingleChildScrollView(
              child: SelectableText(
                state.detailLog,
                style: const TextStyle(
                  color:      C.muted,
                  fontSize:   11.5,
                  fontFamily: 'monospace',
                  height:     1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
