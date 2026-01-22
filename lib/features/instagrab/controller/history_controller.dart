import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instagram_downloader/core/constants.dart';
import 'package:instagram_downloader/features/instagrab/data/models/instagram_media.dart';

class HistoryState {
  final List<DownloadHistoryItem> items;
  final bool isLoading;

  const HistoryState({this.items = const [], this.isLoading = false});

  HistoryState copyWith({List<DownloadHistoryItem>? items, bool? isLoading}) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
}

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>(
      (ref) => HistoryController(),
    );

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController() : super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(AppConstants.historyKey) ?? [];
      final items =
          historyJson
              .map((json) {
                try {
                  return DownloadHistoryItem.fromJson(jsonDecode(json));
                } catch (_) {
                  return null;
                }
              })
              .whereType<DownloadHistoryItem>()
              .toList()
            ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addToHistory(DownloadHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(AppConstants.historyKey) ?? [];
      historyJson.insert(0, jsonEncode(item.toJson()));
      if (historyJson.length > 100)
        historyJson.removeRange(100, historyJson.length);
      await prefs.setStringList(AppConstants.historyKey, historyJson);

      final updatedItems = [item, ...state.items];
      if (updatedItems.length > 100)
        updatedItems.removeRange(100, updatedItems.length);
      state = state.copyWith(items: updatedItems);
    } catch (_) {}
  }

  Future<void> removeFromHistory(DownloadHistoryItem item) async {
    final updatedItems = state.items
        .where(
          (i) =>
              i.localPath != item.localPath ||
              i.downloadedAt != item.downloadedAt,
        )
        .toList();
    state = state.copyWith(items: updatedItems);

    final prefs = await SharedPreferences.getInstance();
    final historyJson = updatedItems
        .map((i) => jsonEncode(i.toJson()))
        .toList();
    await prefs.setStringList(AppConstants.historyKey, historyJson);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.historyKey);
    state = state.copyWith(items: []);
  }
}
