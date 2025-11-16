import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/utils/constants.dart';
import 'package:softplus_options/ui/widgets/payoff_chart_wrapper.dart';
import 'package:softplus_options/ui/widgets/strategy_builder.dart';
import 'package:softplus_options/ui/widgets/volatility_controls.dart';
import 'package:softplus_options/ui/widgets/volatility_surface_wrapper.dart';

// Main workspace layout manager
class LayoutWrapper extends ConsumerWidget {
  const LayoutWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Something like tablet/small windowed app on pc looks okay
        final isWide = constraints.maxWidth > cWideScreen;

        return isWide
            ? _WideLayout()
            : _CompactLayout();
      },
    );
  }
}

// MARK: - Wide Layout
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Left side: defining option strategy
            Expanded(
              child: Column(
                children: const [
                  // Top: chart showing sum of option legs
                  PayoffChartWrapper(),

                  // Bottom: controls of option legs individually
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(cPaddingSmall),
                      child: StrategyManagerWidget(),
                    ),
                  ),
                ],
              ),
            ),

            // Bit of space between
            const VerticalDivider(width: 1, thickness: 1),

            // Right side: fiddle with volatility to see how strategy behaves
            Expanded(
              child: Column(
                children: const [
                  // Top: 3d plot of volatility surface
                  SurfacePlotWrapper(),

                  // Bottom: sliders to control vol parameters
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(cPaddingSmall),
                      child: VolControls(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Compact Layout
class _CompactLayout extends ConsumerStatefulWidget {
  const _CompactLayout();

  @override
  ConsumerState<_CompactLayout> createState() => _CompactLayoutState();
}

// If on mobile, difficult to overview what's where -> prioritize controls
class _CompactLayoutState extends ConsumerState<_CompactLayout> {
  int plotIndex = 0;
  int controlIndex = 0;

  // The four widgets used are split into top/bottom and can be switched between
  static const _topWidgets = [PayoffChartWrapper(), SurfacePlotWrapper()];
  static const _bottomWidgets = [StrategyManagerWidget(), VolControls()];

  // Use a segmented button to switch widgets on top and bottom
  @override
  Widget build(BuildContext context) {
    // Helper to build a full-width segmented button
    Widget fullWidthSegmentedButton({
      required Set<int> selected,
      required void Function(Set<int>) onSelectionChanged,
      required List<ButtonSegment<int>> segments,
    }) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            // Make sure full width
            width: constraints.maxWidth,

            child: SegmentedButton<int>(
              // no check-mark, looks weird
              showSelectedIcon: false,
              selected: selected,
              onSelectionChanged: onSelectionChanged,
              segments: segments,
            ),
          );
        },
      );
    }

    // Actual layout
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top: Plot
            Expanded(child: _topWidgets[plotIndex]),

            // Buttons to switch between payoff plot and 3d vol surf
            Padding(
              padding: const EdgeInsets.all(cPaddingSmall),
              child: fullWidthSegmentedButton(
                selected: {plotIndex},
                onSelectionChanged: (s) => setState(() => plotIndex = s.first),
                segments: const [
                  ButtonSegment(value: 0, label: Text('Payoff')),
                  ButtonSegment(value: 1, label: Text('Vol Surface')),
                ],
              ),
            ),

            // Bottom: Option leg controls
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: cPaddingSmall),
                child: _bottomWidgets[controlIndex],
              ),
            ),

            // Bottom Buttons to switch between individual leg controls and vol controls
            Padding(
              padding: const EdgeInsets.only(
                left: cPaddingSmall,
                right: cPaddingSmall,
                bottom: cPaddingSmall,
              ),
              child: fullWidthSegmentedButton(
                selected: {controlIndex},
                onSelectionChanged: (s) =>
                    setState(() => controlIndex = s.first),
                segments: const [
                  ButtonSegment(value: 0, label: Text('Strategy')),
                  ButtonSegment(value: 1, label: Text('Vol Controls')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
