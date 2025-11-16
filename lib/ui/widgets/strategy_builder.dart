import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:softplus_options/ui/widgets/leg_card.dart';
import 'package:softplus_options/utils/constants.dart';

class StrategyManagerWidget extends ConsumerWidget {
  const StrategyManagerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final currentStrategy = appState.current;

    // The leg state can be saved, so there are two buttons to save/load that are placed first
    return Scaffold(
      body: Column(
        children: [
          // MARK: Save & Load
          Padding(
            padding: const EdgeInsets.only(bottom: cPaddingSmall / 2),
            child: Row(
              // button | spacer | button
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // First button to save state
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showSaveStrategyDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: cPaddingSmall,
                      ),
                    ),
                    child: Text("Save"),
                  ),
                ),

                // Little gap between buttons looks nice
                SizedBox(width: cPaddingSmall / 2),

                // Second button to quickly load snapshot
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openStrategiesDrawer(context, ref),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: cPaddingSmall,
                      ),
                    ),
                    child: Text("Load"),
                  ),
                ),

                // Little gap between buttons looks nice
                SizedBox(width: cPaddingSmall / 2),

                // Second button to quickly load snapshot
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showAddLegDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: cPaddingSmall,
                      ),
                    ),
                    child: Text("+ Add Leg"),
                  ),
                ),
              ],
            ),
          ),

          // MARK: Options list
          // Below is a list of all option legs
          Expanded(
            child: ListView.builder(
              itemCount: currentStrategy.legs.length,
              itemBuilder: (ctx, i) => LegCard(
                leg: currentStrategy.legs[i],
                onChanged: (updated) =>
                    ref.read(appStateProvider.notifier).editLeg(updated),
                onDelete: () => ref
                    .read(appStateProvider.notifier)
                    .removeLeg(currentStrategy.legs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: Save Strategy Dialog
  // Clicking save just prompts for a name for later lookup
  void _showSaveStrategyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save Strategy"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter strategy name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(appStateProvider.notifier)
                    .snapshotCurrent(customName: name);
                // FIXME: switching doesn't work
                Navigator.pop(ctx);

                // Show quick snackbar on top to reassure user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Strategy saved as '$name'")),
                  // ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // MARK: Load Strategies Drawer
  // Slide in a list to let user load back a config from before
  void _openStrategiesDrawer(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(cPaddingSmall),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle bar on top of drawer
            Container(
              margin: const EdgeInsets.only(top: cPaddingSmall),

              // Not too big
              width: 40,
              height: 5,

              // Make it less obvious
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(cPaddingSmall),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Saved Strategies",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // List of all saved snapshots
            Expanded(
              child: appState.history.isEmpty
                  ? const Center(child: Text("No saved strategies yet"))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: appState.historyLength,
                      itemBuilder: (context, index) {
                        final strat = appState[index];
                        // TODO: Maybe show just loaded strategy different?
                        // final isCurrent = strat.name == appState.current.name;
                        final ts = strat.timestamp;

                        return ListTile(
                          // First display name
                          title: Text(strat.name),

                          // Show more information about the snapshot
                          // Nicer display
                          subtitle: Text(
                            "${ts?.year}-${ts?.month}-${ts?.day}    ${strat.legs.length} leg${strat.legs.length == 1 ? '' : 's'}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 26),
                            // TODO: put these guys in more places
                            tooltip: "Delete strategy",
                            onPressed: () =>
                                _confirmAndDeleteStrategy(context, ref, strat),
                          ),
                          onTap: () {
                            ref
                                .read(appStateProvider.notifier)
                                .loadFromHistory(strat.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Loaded: ${strat.name}")),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: Confirm delete
  void _confirmAndDeleteStrategy(
    BuildContext context,
    WidgetRef ref,
    TradingStrategy strat,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Strategy?"),
        content: Text("Permanently delete \"${strat.name}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(appStateProvider.notifier).deleteSnapshot(strat.id);

      if (!context.mounted) return;
      // Close drawer after deletion
      // TODO: redraw instead
      Navigator.pop(context);
    }
  }
}

// MARK: - Add Leg
// Dialog that pops up when clicking FAB
void _showAddLegDialog(BuildContext context, WidgetRef ref) {
  // Input widgets with default params
  var selectedType = 'call';
  final strikeCtrl = TextEditingController(text: '100');
  final qtyCtrl = TextEditingController(text: '1');
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Option Leg'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Segmented Button for Call / Put
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'call', label: Text('Call')),
                ButtonSegment(value: 'put', label: Text('Put')),
              ],
              selected: {selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                // Trigger rebuild
                (ctx as Element).markNeedsBuild();
                selectedType = newSelection.first;
              },
            ),
            const SizedBox(height: 16),

            // Strike Price
            TextFormField(
              controller: strikeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Strike Price',
                helperText: 'Between 50.0 and 150.0',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter strike price';
                }
                final strike = double.tryParse(value);
                if (strike == null) return 'Invalid number';
                if (strike < 50.0 || strike > 150.0) {
                  return 'Must be 50.0 – 150.0';
                }
                return null;
              },
            ),

            // Bit of space
            const SizedBox(height: cPaddingSmall),

            // Handle quantity
            TextFormField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              // only int & neg
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^[+-]?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Quantity',
                helperText: '+ Long, – Short',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Must be a whole number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final strike = double.parse(strikeCtrl.text);
              final quantity = int.parse(qtyCtrl.text);

              ref
                  .read(appStateProvider.notifier)
                  .addLeg(
                    type: selectedType,
                    strike: strike,
                    quantity: quantity,
                  );

              Navigator.pop(ctx);
            }
          },
          child: const Text('Add Leg'),
        ),
      ],
    ),
  );
}
