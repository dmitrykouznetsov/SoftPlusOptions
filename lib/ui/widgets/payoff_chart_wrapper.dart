import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/logic/payoff.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:softplus_options/ui/charts/payoff_chart.dart';
import 'package:softplus_options/utils/constants.dart';

class PayoffChartWrapper extends ConsumerWidget {
  const PayoffChartWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategy = ref.watch(appStateProvider).current;
    final time = ref.watch(timeProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      padding: const EdgeInsets.all(16.0),
      child: strategy.legs.isEmpty
          ? const Center(
              child: Text(
                'Tap + to add Call or Put legs',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(child: PayoffChart()),

                Container(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Row(
                    children: [
                      // TODO: Maybe show in %
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Time ${(time * 100).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: time,
                          min: 0.0,
                          max: 1.0,
                          label: time.toStringAsFixed(2),
                          onChanged: (newValue) =>
                              ref.read(timeProvider.notifier).set(newValue),
                        ),
                      ),

                      // At the end, add a button for information about the math
                      InfoButtonWithExplanation(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// MARK: Info button
class InfoButtonWithExplanation extends StatelessWidget {
  const InfoButtonWithExplanation({super.key});

  void _showExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Space before title
              const SizedBox(height: cPaddingSmall),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2 * cPaddingSmall),
                child: Text(
                  'SoftPlus Options Explanation',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ),

              // Big of padding before explanation
              const SizedBox(height: cPaddingSmall),

              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(2 * cPaddingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THIS APPLICATION IS STRICTLY FOR EDUCATIONAL AND ILLUSTRATIVE PURPOSES ONLY. IT IS NOT A FINANCIAL ADVISORY TOOL, INVESTMENT ADVISORY SERVICE, OR TRADING PLATFORM.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: cMediumTextSize,
                        ),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      const Text(
                        'The option payoff curve looks a lot like a function known as "SoftPlus": ',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      Center(
                        child: Math.tex(
                          r'f(x, p) = p \log(1 + \exp(x / p))',
                          textStyle: const TextStyle(
                            fontSize: cMediumTextSize + 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      Text(
                        'Where p is a smoothing parameter that is linked to time and price of the option (premium). '
                        'To simulate the payoff of an option, we use the following calibration:',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Math.tex(
                          r'\begin{array}{l l} P(S, T) = & f\left(S-K, \frac{A\sqrt{T}}{\log 2}\right) \\ &- f\left(-K, \frac{A\sqrt{T_0}}{\log 2}\right)\end{array}',
                          textStyle: const TextStyle(
                            fontSize: cMediumTextSize + 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      Text(
                        'Where S and T are price and time at which we calculate the payoff of the option contract, '
                        'K is the strike price of the contract, and A is the At-The-Money (ATM) premium you need to pay to purchase the option contract. '
                        'In this app, we set A equal to the IV Offset at T = 0, found in the Vol Controls.',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),

                      // Section on volatility
                      const SizedBox(height: 2 * cPaddingSmall),
                      Text(
                        'Volatility Surface',
                        style: TextStyle(
                          fontSize: cMediumTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      Text(
                        'The Volatility surface is a 3D plot that shows the Implied Volatility (IV) (directly linked to premium of the option) of options across different strikes and time. '
                        'The shape of the volatility surface directly reflects how the market prices the probability and impact of different payoff scenarios (fat tails, crashes, jumps, etc.)',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      Text(
                        'Rising IV "reverts time backward" (makes the option behave as if it had more time left), and falling IV "fast-forwards time" (makes it behave as if expiry is closer). ',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),

                      // Disclaimer
                      const SizedBox(height: 2 * cPaddingSmall),
                      Text(
                        'Disclaimer',
                        style: TextStyle(
                          fontSize: cMediumTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: cPaddingSmall),
                      Text(
                        'All models, calculations, pricing tools, simulations, and outputs provided within this app are simplified "toy models" designed exclusively to help users build intuition about financial derivatives, volatility dynamics, risk management concepts, and mathematical relationships in options pricing. They are deliberately stylized, contain numerous simplifying assumptions, and do not reflect real-world market frictions, transaction costs, liquidity constraints, regulatory requirements, or actual executable prices.',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      color: Colors.grey[600],
      iconSize: 28,
      tooltip: 'Show information',
      onPressed: () => _showExplanation(context),
    );
  }
}
