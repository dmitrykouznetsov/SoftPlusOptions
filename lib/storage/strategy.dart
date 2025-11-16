import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

// Mix shared_preferences with riverpod
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main.dart');
});

// MARK: Helper Functions
// Helper function to locate strategies by id
extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// Save Legs/strategies with unique id
final _uuid = Uuid();

// MARK: Core models

// Volatility parameters that describe the volatility surface
// Simple model of two parabolas interpolated
class VolParams {
  final double a1, a2, b1, b2, c1, c2;
  const VolParams({
    this.a1 = 1.0,
    this.a2 = 0.1,
    this.b1 = 0.2,
    this.b2 = 0.1,
    this.c1 = 0.0,
    this.c2 = 0.1,
  });

  VolParams copyWith({
    double? a1,
    double? a2,
    double? b1,
    double? b2,
    double? c1,
    double? c2,
  }) => VolParams(
    a1: a1 ?? this.a1,
    a2: a2 ?? this.a2,
    b1: b1 ?? this.b1,
    b2: b2 ?? this.b2,
    c1: c1 ?? this.c1,
    c2: c2 ?? this.c2,
  );

  factory VolParams.fromJson(Map<String, dynamic> json) => VolParams(
    a1: (json['a1'] as num).toDouble(),
    a2: (json['a2'] as num).toDouble(),
    b1: (json['b1'] as num).toDouble(),
    b2: (json['b2'] as num).toDouble(),
    c1: (json['c1'] as num).toDouble(),
    c2: (json['c2'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'a1': a1,
    'a2': a2,
    'b1': b1,
    'b2': b2,
    'c1': c1,
    'c2': c2,
  };
}

// MARK: Leg
// Each strategy consists of multiple option legs of which the payoff is summed
class Leg {
  final String id;
  // TODO: rewrite with enum?
  final String type;
  final double strike;
  final int quantity;
  final bool expandInfoEdit;

  const Leg({
    required this.id,
    required this.type,
    required this.strike,
    required this.quantity,
    this.expandInfoEdit = false,
  });

  Leg copyWith({
    String? id,
    String? type,
    double? strike,
    int? quantity,
    bool? expandInfoEdit,
  }) => Leg(
    id: id ?? this.id,
    type: type ?? this.type,
    strike: strike ?? this.strike,
    quantity: quantity ?? this.quantity,
    expandInfoEdit: expandInfoEdit ?? this.expandInfoEdit,
  );

  // Serialize for shared_preferences
  factory Leg.fromJson(Map<String, dynamic> json) => Leg(
    id: json['id'],
    type: json['type'],
    strike: (json['strike'] as num).toDouble(),
    quantity: json['quantity'],
    expandInfoEdit: json['expandInfoEdit'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'strike': strike,
    'quantity': quantity,
    'expandInfoEdit': expandInfoEdit,
  };
}

// MARK: Strategy
// Group options into strategies
class TradingStrategy {
  final String id;
  final String name;
  final VolParams volParams;
  final List<Leg> legs;
  final DateTime? timestamp; // null for the *current* strategy

  const TradingStrategy({
    required this.id,
    required this.name,
    required this.volParams,
    required this.legs,
    this.timestamp,
  });

  TradingStrategy copyWith({
    String? id,
    String? name,
    VolParams? volParams,
    List<Leg>? legs,
    DateTime? timestamp,
  }) => TradingStrategy(
    id: id ?? this.id,
    name: name ?? this.name,
    volParams: volParams ?? this.volParams,
    legs: legs ?? this.legs,
    timestamp: timestamp ?? this.timestamp,
  );

  // Default option you see when launching app fresh
  factory TradingStrategy.initial() => TradingStrategy(
    id: _uuid.v4(),
    name: 'New Strategy',
    volParams: const VolParams(),
    legs: [Leg(id: _uuid.v4(), type: 'call', strike: 100, quantity: 1)],
  );

  factory TradingStrategy.fromJson(Map<String, dynamic> json) =>
      TradingStrategy(
        id: json['id'],
        name: json['name'],
        volParams: VolParams.fromJson(json['volParams']),
        legs: (json['legs'] as List).map((e) => Leg.fromJson(e)).toList(),
        timestamp: json['timestamp'] == null
            ? null
            : DateTime.parse(json['timestamp']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'volParams': volParams.toJson(),
    'legs': legs.map((e) => e.toJson()).toList(),
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };
}

// MARK: AppState
// AppState is the total of many strategies
// One strategy is shown to user at a time, while others are stored in a list (history)
class AppState {
  final TradingStrategy current;
  // Immutable snapshots
  final List<TradingStrategy> history;

  const AppState({required this.current, required this.history});

  // Index access to history
  TradingStrategy operator [](int index) => history[index];
  int get historyLength => history.length;

  factory AppState.initial() => AppState(
    current: TradingStrategy.initial().copyWith(name: 'First Strategy'),
    // history: [],
    history: [
      TradingStrategy(
        id: 'strat-01',
        name: 'Iron Call Butterfly',
        volParams: VolParams(
          a1: 1.0,
          b1: 0.3,
          c1: 0.1,
          a2: 0.3,
          b2: 0.3,
          c2: 0.0,
        ),
        legs: [
          Leg(id: 'leg-01', type: 'call', strike: 120.0, quantity: 1),
          Leg(id: 'leg-02', type: 'call', strike: 100.0, quantity: -2),
          Leg(id: 'leg-03', type: 'call', strike: 80.0, quantity: 1),
        ],
      ),
    ],
  );

  AppState copyWith({
    TradingStrategy? current,
    List<TradingStrategy>? history,
  }) => AppState(
    current: current ?? this.current,
    history: history ?? this.history,
  );

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
    current: TradingStrategy.fromJson(json['current']),
    history: (json['history'] as List)
        .map((e) => TradingStrategy.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'current': current.toJson(),
    'history': history.map((e) => e.toJson()).toList(),
  };
}

// MARK: Notifier
// The main functions to interact with all the datastructures above.
final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

class AppStateNotifier extends Notifier<AppState> {
  static const _key = 'options_trading_app_state_v4';

  late final SharedPreferences _prefs;

  @override
  AppState build() {
    _prefs = ref.read(sharedPrefsProvider);
    final raw = _prefs.getString(_key);
    if (raw == null) return AppState.initial();
    try {
      return AppState.fromJson(jsonDecode(raw));
    } catch (_) {
      _prefs.remove(_key);
      return AppState.initial();
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  // Snapshot the current strategy into history list
  void snapshotCurrent({String? customName}) {
    final now = DateTime.now();
    final ts =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} '
        '${_pad(now.hour)}:${_pad(now.minute)}';
    final name = customName ?? 'Snapshot $ts';

    final snap = state.current.copyWith(
      id: _uuid.v4(),
      name: name,
      timestamp: now,
    );

    state = state.copyWith(history: [...state.history, snap]);
    _save();
  }

  // Helper function for nice naming
  String _pad(int n) => n.toString().padLeft(2, '0');

  // Load a snapshot as a new editable current strategy by id
  void loadFromHistory(String strategyId) {
    final snapshot = state.history.firstWhereOrNull((s) => s.id == strategyId);
    if (snapshot == null) return;

    final newCurrent = snapshot.copyWith(
      id: _uuid.v4(),
      name: '${snapshot.name} (copy)',
      timestamp: null,
    );

    state = state.copyWith(current: newCurrent);
    _save();
  }

  // Delete snapshot by id
  void deleteSnapshot(String strategyId) {
    final newHistory = state.history.where((s) => s.id != strategyId).toList();
    if (newHistory.length == state.history.length) return; // not found

    state = state.copyWith(history: newHistory);
    _save();
  }

  // VolParams mutations (current only)
  void updateVolParams({
    double? a1,
    double? a2,
    double? b1,
    double? b2,
    double? c1,
    double? c2,
  }) {
    state = state.copyWith(
      current: state.current.copyWith(
        volParams: state.current.volParams.copyWith(
          a1: a1,
          a2: a2,
          b1: b1,
          b2: b2,
          c1: c1,
          c2: c2,
        ),
      ),
    );
    _save();
  }

  // Leg mutations (current only)
  // TODO: Choose to save volstate for entire app
  void addLeg({
    required String type,
    required double strike,
    required int quantity,
  }) {
    state = state.copyWith(
      current: state.current.copyWith(
        legs: [
          ...state.current.legs,
          Leg(id: _uuid.v4(), type: type, strike: strike, quantity: quantity),
        ],
      ),
    );
    _save();
  }

  void editLeg(Leg updatedLeg) {
    state = state.copyWith(
      current: state.current.copyWith(
        legs: state.current.legs
            .map((l) => l.id == updatedLeg.id ? updatedLeg : l)
            .toList(),
      ),
    );
    _save();
  }

  void toggleLegEdit(String legId) {
    state = state.copyWith(
      current: state.current.copyWith(
        legs: state.current.legs.map((l) {
          return l.id == legId
              ? l.copyWith(expandInfoEdit: !l.expandInfoEdit)
              : l;
        }).toList(),
      ),
    );
    _save();
  }

  void removeLeg(Leg leg) {
    state = state.copyWith(
      current: state.current.copyWith(
        legs: state.current.legs.where((l) => l.id != leg.id).toList(),
      ),
    );
    _save();
  }

  // Reset current to a fresh default
  void resetCurrent() {
    state = state.copyWith(current: TradingStrategy.initial());
    _save();
  }
}
