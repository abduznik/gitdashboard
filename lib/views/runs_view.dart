import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/gitea.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

class RunsView extends StatelessWidget {
  const RunsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      children: [
        TopBar(
          title:   'Runs',
          leading: IconButton(
            icon:      const Icon(Icons.arrow_back, color: C.muted),
            onPressed: () => state.setView(AppView.workflows),
          ),
          actions: [
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              const Text('live', style: TextStyle(color: C.muted, fontSize: 11)),
            ]),
            IconButton(
              icon:      const Icon(Icons.refresh, color: C.muted),
              onPressed: () => state.refreshRuns(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.loadingRuns && state.runs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child:   CircularProgressIndicator(color: C.accent),
          )
        else if (state.runs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child:   Text('No runs yet.', style: TextStyle(color: C.muted, fontSize: 13)),
          )
        else
          Expanded(
            child: ListView.builder(
              padding:     EdgeInsets.zero,
              itemCount:   state.runs.length,
              itemBuilder: (_, i) {
                final run  = state.runs[i];
                final s    = (run['status']     as String? ?? 'unknown').toLowerCase();
                final c    = (run['conclusion'] as String? ?? '').toLowerCase();
                final key  = c.isNotEmpty ? c : s;
                final color = statusColor(key);
                final icon  = statusIcon(key);
                final name  = wfDisplayName(run);
                final num   = '#${run['run_number'] ?? run['id'] ?? '?'}';
                final t     = fmtTime(run['created_at'] as String?);

                return GCard(
                  onTap: () => state.openRunDetail(run),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines:  1,
                                overflow:  TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: C.text, fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('$num · $t',
                                style: const TextStyle(color: C.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: C.muted, size: 18),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
