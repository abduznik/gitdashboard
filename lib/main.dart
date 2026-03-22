import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'theme.dart';
import 'views/setup_view.dart';
import 'views/workflows_view.dart';
import 'views/run_form_view.dart';
import 'views/runs_view.dart';
import 'views/run_detail_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child:  const GiteaDashApp(),
    ),
  );
}

class GiteaDashApp extends StatelessWidget {
  const GiteaDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        'Gitea Dashboard',
      theme:        appTheme,
      debugShowCheckedModeBanner: false,
      home:         const MainShell(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: _buildView(state.view),
      ),
    );
  }

  Widget _buildView(AppView view) {
    switch (view) {
      case AppView.setup:
        return const SingleChildScrollView(child: SetupView());
      case AppView.workflows:
        return const SingleChildScrollView(child: WorkflowsView());
      case AppView.runForm:
        return const RunFormView();
      case AppView.runs:
        return const RunsView();
      case AppView.runDetail:
        return const RunDetailView();
    }
  }
}
