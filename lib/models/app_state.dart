import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/gitea.dart';
import '../models/config.dart';

enum AppView { setup, workflows, runForm, runs, runDetail }

class AppState extends ChangeNotifier {
  AppConfig cfg = AppConfig.empty();

  GiteaAPI? api;
  String?   owner;
  String?   repo;

  List<Map<String, dynamic>> workflows = [];
  List<Map<String, dynamic>> runs      = [];
  Map<String, dynamic>?      activeWf;
  Map<String, dynamic>?      selectedRun;

  AppView view = AppView.setup;

  String detailLog   = 'Loading...';
  bool   loadingWf   = false;
  bool   loadingRuns = false;

  Timer? _pollTimer;

  // ── Boot ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    cfg = await ConfigStore.load();
    if (cfg.instances.isEmpty) {
      view = AppView.setup;
      notifyListeners();
      return;
    }
    _applyInstance();
  }

  void _applyInstance() {
    final inst = cfg.instances[cfg.activeInstance];
    api = GiteaAPI(inst.url, inst.token);
    final activeRepo = cfg.activeRepo ?? (inst.repos.isNotEmpty ? inst.repos.first : null);
    if (activeRepo != null) {
      switchRepo(activeRepo);
    } else {
      view = AppView.workflows;
      notifyListeners();
    }
    _startPolling();
  }

  // ── Setup ─────────────────────────────────────────────────────────────

  Future<String?> connect(String url, String token, String repoStr) async {
    try {
      final testApi = GiteaAPI(url, token);
      final parts   = parseOwnerRepo(repoStr);
      await testApi.checkRepo(parts[0], parts[1]);

      final inst = GiteaInstance(url: url, token: token, repos: [repoStr]);
      cfg.instances.add(inst);
      cfg.activeInstance = cfg.instances.length - 1;
      cfg.activeRepo = repoStr;
      await ConfigStore.save(cfg);

      api = GiteaAPI(url, token);
      switchRepo(repoStr);
      _startPolling();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Repo switching ────────────────────────────────────────────────────

  void switchRepo(String repoStr) {
    final parts = parseOwnerRepo(repoStr);
    owner = parts[0];
    repo  = parts[1];
    cfg.activeRepo = repoStr;
    ConfigStore.save(cfg);
    workflows = [];
    runs      = [];
    view      = AppView.workflows;
    notifyListeners();
    refreshWorkflows();
    refreshRuns();
  }

  Future<void> addRepo(String repoStr) async {
    if (cfg.instances.isEmpty) return;
    final inst = cfg.instances[cfg.activeInstance];
    if (!inst.repos.contains(repoStr)) {
      inst.repos.add(repoStr);
      await ConfigStore.save(cfg);
    }
    switchRepo(repoStr);
  }

  // ── Data refresh ──────────────────────────────────────────────────────

  Future<void> refreshWorkflows() async {
    if (api == null) return;
    loadingWf = true;
    notifyListeners();
    try {
      final wfs = await api!.getWorkflows(owner!, repo!);
      for (final wf in wfs) {
        final parsed = await api!.getWorkflowYaml(owner!, repo!, wf['path'] ?? '');
        if (parsed != null) {
          final onBlock = (parsed['on'] ?? parsed['true'] ?? {}) as Map;
          final wd      = (onBlock['workflow_dispatch'] ?? {}) as Map;
          wf['_inputs'] = (wd['inputs'] ?? {}) as Map;
        } else {
          wf['_inputs'] = <String, dynamic>{};
        }
      }
      workflows = wfs;
    } catch (e) {
      print('[ERROR] workflows: $e');
    }
    loadingWf = false;
    notifyListeners();
  }

  Future<void> refreshRuns() async {
    if (api == null) return;
    loadingRuns = true;
    notifyListeners();
    try {
      runs = await api!.getRuns(owner!, repo!);
    } catch (e) {
      print('[ERROR] runs: $e');
    }
    loadingRuns = false;
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: cfg.pollInterval),
      (_) => refreshRuns(),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void openRunForm(Map<String, dynamic> wf) {
    activeWf = wf;
    view = AppView.runForm;
    notifyListeners();
  }

  void openRunDetail(Map<String, dynamic> run) {
    selectedRun = run;
    detailLog   = 'Loading jobs...';
    view = AppView.runDetail;
    notifyListeners();
    _loadRunDetail(run);
  }

  Future<void> _loadRunDetail(Map<String, dynamic> run) async {
    final lines = <String>[];
    final runId = run['id'];

    try {
      // Step 1: get all jobs for this run
      final jobs = await api!.getJobsForRun(owner!, repo!, runId);

      if (jobs.isEmpty) {
        // Gitea might not expose jobs endpoint — fall back to run-level log attempt
        final logs = await api!.getJobLogs(owner!, repo!, runId);
        if (logs != null && logs.isNotEmpty) {
          lines.add('─' * 40);
          lines.add('LOGS');
          lines.add('─' * 40);
          lines.addAll(stripAnsi(logs).split('\n'));
        } else {
          lines.add('No jobs or logs found for this run.');
          lines.add('');
          lines.add('Run ID: $runId');
          lines.add('Status: ${run['status'] ?? 'unknown'}');
          lines.add('Conclusion: ${run['conclusion'] ?? 'pending'}');
        }
      } else {
        // Step 2: for each job, fetch its logs
        for (final job in jobs) {
          final jname   = job['name'] as String? ?? 'job';
          final jstatus = ((job['conclusion'] ?? job['status'] ?? 'unknown') as String).toLowerCase();
          final jobId   = job['id'];

          lines.add('─' * 40);
          lines.add('JOB: ${jname.toUpperCase()}  [${jstatus.toUpperCase()}]');
          lines.add('─' * 40);

          // Print steps summary
          final steps = (job['steps'] as List?) ?? [];
          for (final step in steps) {
            final sname   = step['name'] as String? ?? 'step';
            final sstatus = ((step['conclusion'] ?? step['status'] ?? '') as String).toLowerCase();
            final icon = sstatus == 'success' ? 'OK  '
                       : sstatus == 'failure' ? 'FAIL'
                       : '... ';
            lines.add('  [$icon] $sname');
          }

          lines.add('');

          // Step 3: fetch full logs for this job
          final logs = await api!.getJobLogs(owner!, repo!, jobId);
          if (logs != null && logs.isNotEmpty) {
            final logLines = stripAnsi(logs).split('\n');
            // Show last 150 lines to avoid huge walls of text
            final trimmed = logLines.length > 150
                ? ['... (${logLines.length - 150} lines above)', ...logLines.sublist(logLines.length - 150)]
                : logLines;
            lines.addAll(trimmed);
          } else {
            lines.add('(no logs available for this job)');
          }

          lines.add('');
        }
      }
    } catch (e) {
      lines.add('Error loading run detail: $e');
    }

    detailLog = lines.join('\n');
    notifyListeners();
  }

  void reloadRunDetail() {
    if (selectedRun != null) {
      detailLog = 'Loading...';
      notifyListeners();
      _loadRunDetail(selectedRun!);
    }
  }

  void setView(AppView v) {
    view = v;
    notifyListeners();
  }

  Future<String?> triggerWorkflow(Map<String, String> inputs) async {
    if (api == null || activeWf == null) return 'Not connected';
    try {
      await api!.triggerWorkflow(
        owner!, repo!,
        activeWf!['id'] ?? activeWf!['name'],
        inputs: inputs.isEmpty ? null : inputs,
      );
      await Future.delayed(const Duration(seconds: 1));
      refreshRuns();
      setView(AppView.runs);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  List<String> get currentRepos {
    if (cfg.instances.isEmpty) return [];
    return cfg.instances[cfg.activeInstance].repos;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
