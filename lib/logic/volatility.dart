import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/logic/payoff.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:vector_math/vector_math.dart' as vm;

// 3D Rotation of the volatility surface
final rotationProvider = NotifierProvider<RotationNotifier, vm.Vector2>(
  RotationNotifier.new,
);

class RotationNotifier extends Notifier<vm.Vector2> {
  @override
  vm.Vector2 build() => vm.Vector2(-0.9, -0.9);

  void addX(double delta) => state = vm.Vector2(state.x + delta, state.y);
  void addY(double delta) => state = vm.Vector2(state.x, state.y + delta);
}

// Expanded state VolControls
final volExpandProvider = NotifierProvider<VolExpand, List<bool>>(
  VolExpand.new,
);

class VolExpand extends Notifier<List<bool>> {
  @override
  List<bool> build() => [false, false];

  void toggle(int index) => state = [...state]..[index] = !state[index];
}

// MARK:
// Calculating volatility
List<vm.Vector3> parabola(
  double a,
  double b,
  double c,
  double xPos, [
  int n = 21,
]) {
  final step = 2.0 / (n - 1);
  return List.generate(n, (i) {
    final y = -1.0 + i * step;
    return vm.Vector3(xPos, y, a * pow((y + c), 2) + b);
  });
}

List<List<vm.Vector3>> surface(VolParams p, [int steps = 20]) {
  final c1 = parabola(p.a1, p.b1, p.c1, -1.0);
  final c2 = parabola(p.a2, p.b2, p.c2, 1.0);

  return List.generate(steps + 1, (i) {
    final t = i / steps;
    final s = sqrt(t);
    return List.generate(c1.length, (j) {
      final p1 = c1[j];
      final p2 = c2[j];
      // Return interpolated values
      return vm.Vector3(
        p1.x + t * (p2.x - p1.x), // linear in time
        p1.y + s * (p2.y - p1.y), // sqrt(t) for strike/vol
        p1.z + s * (p2.z - p1.z),
      );
    });
  });
}

// Derived providers
final plotPointsProvider = Provider<List<List<vm.Vector3>>>((ref) {
  return surface(ref.watch(appStateProvider).current.volParams);
});

final volAtTProvider = Provider<double Function(double)>((ref) {
  final p = ref.watch(appStateProvider).current.volParams;
  final t = ref.watch(timeProvider);

  return (x) {
    final v1 = p.a1 * pow(x + p.c1, 2) + p.b1;
    final v2 = p.a2 * pow(x + p.c2, 2) + p.b2;
    return v2 + sqrt(t) * (v1 - v2);
  };
});

final premiumProvider = Provider<double Function(double)>((ref) {
  final p = ref.watch(appStateProvider).current.volParams;
  return (x) => p.a2 * pow(x + p.c2, 2) + p.b2;
});
