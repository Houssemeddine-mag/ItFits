import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// App-wide push guard against Flutter's
/// `!keyReservation.contains(key)` red screen.
///
/// go_router keys pages by location, so pushing the identical location twice
/// — double-tap, or two widget instances (History card + Detail Continue)
/// racing the same target — puts two pages with the same key on the stack
/// and crashes the Navigator. Per-widget `_navigating` flags are not enough:
/// State objects can be recreated on stream rebuilds, resetting the flag.
/// This module-level cooldown survives all of that.
final Map<String, DateTime> _lastPushAt = {};

/// Pushes [target] unless we are already there or pushed it within
/// [cooldown]. Never throws — navigation failures degrade to a no-op.
Future<void> safePush(
  BuildContext context,
  String target, {
  Duration cooldown = const Duration(seconds: 2),
}) async {
  final now = DateTime.now();
  final last = _lastPushAt[target];
  if (last != null && now.difference(last) < cooldown) return;
  try {
    if (GoRouterState.of(context).uri.toString() == target) return;
  } catch (_) {
    // No GoRouter in scope — let push throw below and swallow it.
  }
  _lastPushAt[target] = now;
  // Prune stale entries so the map can't grow unbounded.
  if (_lastPushAt.length > 50) {
    _lastPushAt.removeWhere((_, t) => now.difference(t) > cooldown);
  }
  try {
    await context.push(target);
  } catch (e) {
    debugPrint('safePush($target) failed: $e');
  }
}
