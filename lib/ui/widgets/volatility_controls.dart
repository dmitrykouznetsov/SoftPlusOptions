import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:softplus_options/logic/volatility.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:softplus_options/utils/constants.dart';

class VolControls extends ConsumerWidget {
  const VolControls({super.key});

  static const _sections = [
    _Section(
      'Towards Expiry (Time = 100)',
      ['a1', 'b1', 'c1'],
      [0.0, 10.0, -20],
      [200.0, 100.0, 20.0],
    ),
    _Section('At Purchase (Time = 0)', ['a2', 'b2', 'c2'], [0.0, 10.0, -50], [
      100.0,
      40.0,
      50.0,
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(appStateProvider).current.volParams;

    return Padding(
      // FIXME: Poorly defined dimensions somewhere...
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        child: Column(
          children: _sections
              .asMap()
              .entries
              .map(
                (entry) => _ParamCard(
                  sectionIndex: entry.key,
                  section: entry.value,
                  params: params,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// MARK: Parameters Card
class _ParamCard extends ConsumerWidget {
  // late bool _expanded;
  final int sectionIndex;
  final _Section section;
  final VolParams params;

  const _ParamCard({
    required this.sectionIndex,
    required this.section,
    required this.params,
  });

  double _get(VolParams p, String f) => switch (f) {
    'a1' => p.a1,
    'a2' => p.a2,
    'b1' => p.b1,
    'b2' => p.b2,
    'c1' => p.c1,
    'c2' => p.c2,
    _ => 0.0,
  };

  String _labels(String f) => switch (f[0]) {
    'a' => 'Convexity',
    'b' => 'IV Offset',
    'c' => 'Price Skew',
    _ => '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(volExpandProvider)[sectionIndex];

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () =>
                      ref.read(volExpandProvider.notifier).toggle(sectionIndex),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref
                        .read(volExpandProvider.notifier)
                        .toggle(sectionIndex),
                    child: Text(
                      section.title,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: cPaddingSmall,
                right: cPaddingSmall,
                bottom: cPaddingSmall,
              ),
              child: Column(
                children: List.generate(section.fields.length, (i) {
                  final field = section.fields[i];
                  final value = _get(params, field) * 100;
                  final min = section.mins[i];
                  final max = section.maxs[i];

                  return _Slider(
                    label: _labels(field),
                    value: value,
                    min: min,
                    max: max,
                    onChanged: (v) {
                      final normalized = v / 100;
                      switch (field) {
                        case 'a1':
                          ref
                              .read(appStateProvider.notifier)
                              .updateVolParams(a1: normalized);
                          break;
                        case 'a2':
                          ref
                              .read(appStateProvider.notifier)
                              .updateVolParams(a2: normalized);
                          break;
                        case 'b1':
                          ref
                              .read(appStateProvider.notifier)
                              .updateVolParams(b1: normalized);
                          break;
                        case 'b2':
                          ref
                              .read(appStateProvider.notifier)
                              .updateVolParams(b2: normalized);
                          break;
                        case 'c1':
                          ref
                              .read(appStateProvider.notifier)
                              .updateVolParams(c1: normalized);
                          break;
                        case 'c2':
                          ref
                              .read(appStateProvider.notifier)
                              .updateVolParams(c2: normalized);
                          break;
                      }
                    },
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// MARK: Slider widget
class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(label, style: const TextStyle(fontSize: cMediumTextSize)),
              ),

              // Editable Quantity Field
              SizedBox(
                width: 70,
                child: TextField(
                  controller:
                      TextEditingController(text: value.toStringAsFixed(2))
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: value.toStringAsFixed(2).length),
                        ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    border: const UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  onSubmitted: (input) {
                    final newValue = double.tryParse(input) ?? value;
                    final clampedValue = newValue.clamp(min, max);
                    onChanged(clampedValue);
                  },
                  onTap: () {
                    // Select all on tap for easy replacement
                    final controller = TextEditingController(
                      text: value.toStringAsFixed(2),
                    );
                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    );
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * 2).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// Pure data config
class _Section {
  final String title;
  final List<String> fields;
  final List<double> mins, maxs;
  const _Section(this.title, this.fields, this.mins, this.maxs);
}
