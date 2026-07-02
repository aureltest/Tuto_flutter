import 'dart:convert';
import 'record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordService {
  static const _key = 'records';

  Future<List<Record>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => Record.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> save(Record record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await load();
    records.add(record);
    final raw = records.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }
}