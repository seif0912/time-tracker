import 'history_entry.dart';

class HistoryGroup {
  const HistoryGroup({required this.date, required this.entries});

  final DateTime date;
  final List<HistoryEntry> entries;
}
