import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/logic/payoff.dart';
import 'package:softplus_options/utils/constants.dart';

class PayoffChart extends ConsumerWidget {
  const PayoffChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minPrice = ref.watch(minPriceProvider);
    final maxPrice = ref.watch(maxPriceProvider);

    final payoff = ref.watch(payoffProvider);
    final finalPayoff = ref.watch(finalPayoffProvider);
    final initPayoff = ref.watch(initialPayoffProvider);
    final zeroLine = ref.watch(zeroLineProvider);

    // Split payoff into positive / negative parts for filling area
    final List<FlSpot> positive = [];
    final List<FlSpot> negative = [];

    for (final spot in payoff) {
      if (spot.y >= 0) {
        positive.add(spot);
      } else {
        negative.add(spot);
      }
    }

    // Add the zero-line anchor points so the area closes nicely
    if (positive.isNotEmpty) {
      positive.insert(0, FlSpot(positive.first.x, 0));
      positive.add(FlSpot(positive.last.x, 0));
    }
    if (negative.isNotEmpty) {
      negative.insert(0, FlSpot(negative.first.x, 0));
      negative.add(FlSpot(negative.last.x, 0));
    }

    // Compute y-range for the chart
    final maxFLoss = finalPayoff
        .map((e) => e.y)
        .reduce((a, b) => a < b ? a : b);
    final maxFProfit = finalPayoff
        .map((e) => e.y)
        .reduce((a, b) => a > b ? a : b);

    final maxSLoss = initPayoff
        .map((e) => e.y)
        .reduce((a, b) => a < b ? a : b);
    final maxSProfit = initPayoff
        .map((e) => e.y)
        .reduce((a, b) => a > b ? a : b);

    final maxLoss = min(maxFLoss, maxSLoss);
    final maxProfit = max(maxFProfit, maxSProfit);

    final data = LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          axisNameWidget: Text('Payoff'),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 20,
          ),
          axisNameWidget: Text('Price'),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: minPrice,
      maxX: maxPrice,
      minY: maxLoss - 10,
      maxY: maxProfit + 10,

      clipData: FlClipData.all(),

      lineBarsData: [
        // Green Profit Area
        if (positive.isNotEmpty)
          LineChartBarData(
            spots: positive,
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.25),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),

        // Red Loss Area
        if (negative.isNotEmpty)
          LineChartBarData(
            spots: negative,
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            aboveBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.25),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),

        // Zero reference line
        LineChartBarData(
          spots: zeroLine,
          isCurved: false,
          color: Colors.black,
          barWidth: 1,
          dotData: const FlDotData(show: false),
          dashArray: [8, 4],
        ),

        // Payoff line (thick blue)
        LineChartBarData(
          spots: payoff,
          isCurved: false,
          color: Colors.blue.shade700,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          // we will fill the areas with separate BarAreaData below
        ),

        // Final payoff line (black dashed)
        LineChartBarData(
          spots: finalPayoff,
          isCurved: false,
          color: Colors.black,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [4, 4],
        ),
      ],

      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        getTouchLineStart: (data, index) => 0,
        touchTooltipData: LineTouchTooltipData(
          tooltipPadding: const EdgeInsets.all(8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> touched) {
            return touched.asMap().entries.map((entry) {
              final index = entry.key;
              final spot = entry.value;
              if (index != 1) {
                return null;
              }

              final textStyle = TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              );

              return LineTooltipItem(
                'Stock: ${spot.x.toStringAsFixed(2)}\n'
                'Payoff: ${spot.y.toStringAsFixed(2)}',
                textStyle,
              );
            }).toList();
          },
        ),
      ),

      // TODO: add markers for each position
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: 100.0,
            color: Colors.purple,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: TextStyle(color: Colors.purple, fontSize: cSmallTextSize),
              labelResolver: (l) => 'S₀',
            ),
          ),
          // Strike lines
          // ...strikeXs.map(
          //   (x) => VerticalLine(
          //     x: x,
          //     color: Colors.purple,
          //     strokeWidth: 1.5,
          //     dashArray: [5, 5],
          //     label: VerticalLineLabel(
          //       show: true,
          //       alignment: Alignment.topCenter,
          //       style: const TextStyle(color: Colors.purple, fontSize: 10),
          //       // text: 'K',
          //     ),
          //   ),
          // ),
        ],
      ),
    );
    return LineChart(data, duration: Duration.zero, curve: Curves.linear);
  }
}
