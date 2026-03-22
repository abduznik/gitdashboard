import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import 'widgets.dart';

class WorkflowsView extends StatelessWidget {
  const WorkflowsView({super.key});

  void _showAddRepo(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Repository',
                style: TextStyle(color: C.text, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller:  ctrl,
              autofocus:   true,
              style:       const TextStyle(color: C.text),
              decoration:  gField('owner/repo', hint: 'arb/my-repo'),
            ),
            const SizedBox(height: 16),
            TapButton(
              text:            'Add',
              color:           C.accent2,
              horizontalMargin: 0,
              onTap: () {
                final repo = ctrl.text.trim();
                if (repo.isNotEmpty) {
                  Navigator.pop(ctx);
                  context.read<AppState>().addRepo(repo);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final repos = state.currentRepos;

    return Column(
      children: [
        TopBar(
          title: 'Gitea',
          leading: const Icon(Icons.rocket_launch, color: C.accent, size: 20),
          actions: [
            IconButton(
              icon:    const Icon(Icons.history,   color: C.accent2),
              tooltip: 'Runs',
              onPressed: () => state.setView(AppView.runs),
            ),
            IconButton(
              icon:    const Icon(Icons.add,    color: C.muted),
              tooltip: 'Add repo',
              onPressed: () => _showAddRepo(context),
            ),
            IconButton(
              icon:      const Icon(Icons.refresh, color: C.muted),
              onPressed: () => state.refreshWorkflows(),
            ),
          ],
        ),

        // Repo picker
        if (repos.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DropdownButtonFormField<String>(
              value:       state.cfg.activeRepo,
              dropdownColor: C.surface2,
              style:       const TextStyle(color: C.text, fontSize: 13),
              decoration:  gField('Repository'),
              items: repos.map((r) =>
                DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) { if (v != null) state.switchRepo(v); },
            ),
          )
        else if (repos.length == 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(repos.first,
                style: const TextStyle(color: C.muted, fontSize: 13)),
          ),

        const SectionHeader('WORKFLOWS'),

        if (state.loadingWf)
          const Padding(
            padding: EdgeInsets.all(32),
            child:   CircularProgressIndicator(color: C.accent),
          )
        else if (state.workflows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child:   Text('No workflows found.', style: TextStyle(color: C.muted, fontSize: 13)),
          )
        else
          ...state.workflows.map((wf) => GCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wf['name'] ?? '', style: const TextStyle(
                          color: C.text, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(wf['path'] ?? '', style: const TextStyle(color: C.muted, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => state.openRunForm(wf),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:        C.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Run',
                        style: TextStyle(color: Color(0xFF0d1117),
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )),

        const SizedBox(height: 20),
      ],
    );
  }
}
