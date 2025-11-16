import 'dart:math';

// Softplus
double f(double x, double p) {
  return p * log(1 + exp(x / p));
}

// Core pricing function P
double P(double s, double t, double K, double a, {double t0 = 1.0}) {
  final p0 = f(-K, a * sqrt(t0) / log(2));
  return f(s - K, a * sqrt(t) / log(2)) - p0;
}

// Global epsilon
const double epsilon = 0.0001;

// Abstract base for options
abstract class Option {
  double call(double s, double t);
}

// Call Option
class Call implements Option {
  final int n;
  final double k;
  final double a;
  final double s;
  final double deltaS;
  final double t;
  final double deltaT;

  const Call({
    this.n = 1,
    this.k = 0.0,
    this.a = 0.05,
    this.s = 0.0,
    this.deltaS = 0.0,
    this.t = 1.0,
    this.deltaT = 1.0,
  });

  @override
  double call(double s, double t) {
    if (t <= this.t - deltaT) {
      if (deltaS != 0.0) {
        return n * P(deltaS, epsilon, k, a, t0: deltaT);
      } else {
        return n * P(s - this.s, epsilon, k, a, t0: deltaT);
      }
    } else {
      return n * P(s - this.s, t - this.t + deltaT, k, a, t0: deltaT);
    }
  }
}

// Put Option
class Put implements Option {
  final int n;
  final double k;
  final double a;
  final double s;
  final double deltaS;
  final double t;
  final double deltaT;

  const Put({
    this.n = 1,
    this.k = 0.0,
    this.a = 0.05,
    this.s = 0.0,
    this.deltaS = 0.0,
    this.t = 1.0,
    this.deltaT = 1.0,
  });

  @override
  double call(double s, double t) {
    if (t <= this.t - deltaT) {
      if (deltaS != 0.0) {
        return n * P(deltaS, epsilon, k, a, t0: deltaT);
      } else {
        return n * P(-s + this.s, epsilon, k, a, t0: deltaT);
      }
    } else {
      return n * P(-s + this.s, t - this.t + deltaT, k, a, t0: deltaT);
    }
  }
}
