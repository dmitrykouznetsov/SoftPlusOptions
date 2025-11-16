import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/logic/softplus.dart';
import 'package:softplus_options/logic/volatility.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:softplus_options/utils/constants.dart';

// Chart configuration
final minPriceProvider = Provider<double>((ref) => cPayoffGraphMin);
final maxPriceProvider = Provider<double>((ref) => cPayoffGraphMax);
final pointsProvider = Provider<int>((ref) => cGraphResolution);

// User controlled time (0.0 = now, 1.0 = expiration)
final timeProvider = NotifierProvider<Time, double>(Time.new);

class Time extends Notifier<double> {
  @override
  double build() => 0.0;

  // Update current time progress
  void set(double newValue) => state = newValue.clamp(0.0, 1.0);
}

// Payoff Calculation Logic

// Precompute price points accross chart range
final pricePointsProvider = Provider<List<double>>((ref) {
  final min = ref.watch(minPriceProvider);
  final max = ref.watch(maxPriceProvider);
  final points = ref.watch(pointsProvider);

  final step = (max - min) / points;
  return List.generate(points + 1, (i) => min + i * step);
});

// Type alias for a function that computes option price at given stock level and volatility
typedef OptionPricer = double Function(double s, double vol);

// Creates a pricer function for a Call option
OptionPricer callPricer(double strikeNormalized, double premium, int quantity) {
  final call = Call(
    n: quantity,
    k: strikeNormalized,
    a: premium,
    s: 0.0,
    t: 1.0,
    deltaT: 1.0,
  );
  return (s, vol) => 100 * call(s, vol);
}

// Creates a pricer function for a Put option
OptionPricer putPricer(double strikeNormalized, double premium, int quantity) {
  final put = Put(
    n: quantity,
    k: -strikeNormalized,
    a: premium,
    s: 0.0,
    t: 1.0,
    deltaT: 1.0,
  );
  return (s, vol) => 100 * put(s, vol);
}

// Builds a list of pricer functions for all legs in the strategy
List<OptionPricer> buildPricers(
  List<Leg> strategy,
  double Function(double) premium,
) {
  return strategy.map((leg) {
    final strikeNorm = leg.strike / 100 - 1;
    final premiumAtStrike = premium(strikeNorm);

    return leg.type == 'call'
        ? callPricer(strikeNorm, premiumAtStrike, leg.quantity)
        : putPricer(strikeNorm, premiumAtStrike, leg.quantity);
  }).toList();
}

// Generates price points across the chart range
List<double> generatePricePoints(double min, double max, int points) {
  final step = (max - min) / points;
  return List.generate(points + 1, (i) => min + i * step);
}

// Computes total payoff at a given stock price using list of pricers
double computePayoffAtPrice(
  double sNormalized,
  double vol,
  List<OptionPricer> pricers,
) {
  return pricers.fold(0.0, (sum, pricer) => sum + pricer(sNormalized, vol));
}

// MARK: Payoff Providers

/// Payoff at current time (interpolated volatility)
final payoffProvider = Provider<List<FlSpot>>((ref) {
  final strategy = ref.watch(appStateProvider).current;
  final time = ref.watch(timeProvider);
  final premium = ref.watch(premiumProvider);
  final volAtT = ref.watch(volAtTProvider);
  final pricePoints = ref.watch(pricePointsProvider);

  if (strategy.legs.isEmpty) return [];

  final pricers = buildPricers(strategy.legs, premium);

  return pricePoints
      .map((stockPrice) {
        final s = stockPrice / 100 - 1;

        // Interpolate volatility: blend current vol and target vol based on time
        final factor = (volAtT(s) - premium(s)) / premium(s);
        final tVol = (1.0 - time) * (1 + factor * time);

        final payoff = computePayoffAtPrice(s, tVol, pricers);
        return FlSpot(stockPrice, payoff);
      })
      .where((spot) => spot.x.isFinite && spot.y.isFinite)
      .toList();
});

// Payoff at expiration
final finalPayoffProvider = Provider<List<FlSpot>>((ref) {
  final strategy = ref.watch(appStateProvider).current;
  final pricePoints = ref.watch(pricePointsProvider);
  final premium = ref.watch(premiumProvider);

  if (strategy.legs.isEmpty) return [];

  final pricers = buildPricers(strategy.legs, premium);

  return pricePoints.map((stockPrice) {
    final s = stockPrice / 100 - 1;
    final payoff = computePayoffAtPrice(s, 0.0, pricers);
    return FlSpot(stockPrice, payoff);
  }).toList();
});

// For axis range
final initialPayoffProvider = Provider<List<FlSpot>>((ref) {
  final strategy = ref.watch(appStateProvider).current;
  final pricePoints = ref.watch(pricePointsProvider);
  final premium = ref.watch(premiumProvider);

  if (strategy.legs.isEmpty) return [];

  final pricers = buildPricers(strategy.legs, premium);

  return pricePoints.map((stockPrice) {
    final s = stockPrice / 100 - 1;
    final payoff = computePayoffAtPrice(s, 1.0, pricers);
    return FlSpot(stockPrice, payoff);
  }).toList();
});

/// Horizontal zero line for reference
final zeroLineProvider = Provider<List<FlSpot>>((ref) {
  final pricePoints = ref.watch(pricePointsProvider);
  return pricePoints.map((price) => FlSpot(price, 0.0)).toList();
});
