import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GiteaInstance {
  String url;
  String token;
  List<String> repos;

  GiteaInstance({required this.url, required this.token, required this.repos});

  factory GiteaInstance.fromJson(Map<String, dynamic> j) => GiteaInstance(
        url:   j['url'] ?? '',
        token: j['token'] ?? '',
        repos: List<String>.from(j['repos'] ?? []),
      );

  Map<String, dynamic> toJson() => {'url': url, 'token': token, 'repos': repos};
}

class AppConfig {
  List<GiteaInstance> instances;
  int activeInstance;
  String? activeRepo;
  int pollInterval;

  AppConfig({
    required this.instances,
    required this.activeInstance,
    this.activeRepo,
    this.pollInterval = 5,
  });

  factory AppConfig.empty() => AppConfig(instances: [], activeInstance: 0);

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        instances:      (j['instances'] as List? ?? [])
            .map((e) => GiteaInstance.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeInstance: j['active_instance'] ?? 0,
        activeRepo:     j['active_repo'],
        pollInterval:   j['poll_interval'] ?? 5,
      );

  Map<String, dynamic> toJson() => {
        'instances':       instances.map((e) => e.toJson()).toList(),
        'active_instance': activeInstance,
        'active_repo':     activeRepo,
        'poll_interval':   pollInterval,
      };
}

class ConfigStore {
  static const _key = 'giteadash_config';

  static Future<AppConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppConfig.empty();
    try {
      return AppConfig.fromJson(jsonDecode(raw));
    } catch (_) {
      return AppConfig.empty();
    }
  }

  static Future<void> save(AppConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cfg.toJson()));
  }
}
