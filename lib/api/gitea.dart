import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

class GiteaAPI {
  final String base;
  final Map<String, String> headers;

  GiteaAPI(String url, String token)
      : base = url.replaceAll(RegExp(r'/$'), ''),
        headers = {
          'Authorization': 'token $token',
          'Content-Type':  'application/json',
        };

  Future<dynamic> _get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$base/api/v1$path');
    if (params != null) uri = uri.replace(queryParameters: params);
    final r = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    if (r.statusCode >= 400) throw Exception('HTTP ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body);
  }

  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$base/api/v1$path');
    final r = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode >= 400) throw Exception('HTTP ${r.statusCode}: ${r.body}');
    return r;
  }

  Future<void> checkRepo(String owner, String repo) async {
    await _get('/repos/$owner/$repo');
  }

  Future<List<Map<String, dynamic>>> getWorkflows(String owner, String repo) async {
    try {
      final data = await _get('/repos/$owner/$repo/actions/workflows');
      return List<Map<String, dynamic>>.from(data['workflows'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getWorkflowYaml(String owner, String repo, String path) async {
    try {
      final uri = Uri.parse('$base/$owner/$repo/raw/branch/main/$path');
      final r = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final parsed = loadYaml(r.body);
        return _yamlToMap(parsed);
      }
    } catch (ex) {
      print('[YAML] $ex');
    }
    return null;
  }

  static dynamic _yamlToMap(dynamic node) {
    if (node is YamlMap) {
      return node.map((k, v) => MapEntry(k.toString(), _yamlToMap(v)));
    } else if (node is YamlList) {
      return node.map(_yamlToMap).toList();
    }
    return node;
  }

  Future<void> triggerWorkflow(String owner, String repo, dynamic wfId,
      {Map<String, String>? inputs}) async {
    final body = <String, dynamic>{'ref': 'main'};
    if (inputs != null && inputs.isNotEmpty) body['inputs'] = inputs;
    await _post('/repos/$owner/$repo/actions/workflows/$wfId/dispatches', body: body);
  }

  Future<List<Map<String, dynamic>>> getRuns(String owner, String repo,
      {int limit = 20}) async {
    try {
      final data = await _get('/repos/$owner/$repo/actions/runs',
          params: {'limit': '$limit'});
      return List<Map<String, dynamic>>.from(data['workflow_runs'] ?? []);
    } catch (_) {
      return [];
    }
  }

  /// Fetch all jobs for a given run ID.
  Future<List<Map<String, dynamic>>> getJobsForRun(
      String owner, String repo, dynamic runId) async {
    try {
      final data = await _get('/repos/$owner/$repo/actions/runs/$runId/jobs');
      final jobs = data['workflow_jobs'] ?? data['jobs'] ?? [];
      return List<Map<String, dynamic>>.from(jobs);
    } catch (e) {
      print('[getJobsForRun] $e');
      return [];
    }
  }

  /// Fetch raw logs for a specific job ID.
  Future<String?> getJobLogs(String owner, String repo, dynamic jobId) async {
    try {
      final uri = Uri.parse('$base/api/v1/repos/$owner/$repo/actions/jobs/$jobId/logs');
      final r = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return r.body;
      print('[getJobLogs] status=${r.statusCode}');
    } catch (e) {
      print('[getJobLogs] $e');
    }
    return null;
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String stripAnsi(String t) => t.replaceAll(RegExp(r'\x1b\[[0-9;]*m'), '');

String fmtTime(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2)} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '-';
  }
}

List<String> parseOwnerRepo(String s) {
  final parts = s.replaceAll(RegExp(r'^/|/$'), '').split('/');
  if (parts.length >= 2) return [parts[parts.length - 2], parts.last];
  return ['', ''];
}

/// Derive a readable name from any run — no hardcoded yml list.
String wfDisplayName(Map<String, dynamic> run) {
  final wfName = run['name'] as String?;
  if (wfName != null && wfName.isNotEmpty) return wfName;

  final path = run['path'] as String? ?? '';
  final wfId = path.contains('@') ? path.split('@').first : path;
  final filename = wfId.split('/').last;
  if (filename.isNotEmpty) {
    return filename
        .replaceAll('.yml', '')
        .replaceAll('.yaml', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  return run['display_title'] as String? ?? 'Run #${run['id']}';
}
