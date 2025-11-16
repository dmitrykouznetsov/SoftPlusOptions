import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:softplus_options/storage/strategy.dart';
import 'package:softplus_options/utils/constants.dart';

// strike & premium sliders + quantity mod
class LegCard extends StatefulWidget {
  final Leg leg;
  final ValueChanged<Leg> onChanged;
  final VoidCallback onDelete;

  const LegCard({
    super.key,
    required this.leg,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<LegCard> createState() => _LegCardState();
}

// MARK: Leg Card State
class _LegCardState extends State<LegCard> {
  late bool _expanded;
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _expanded = false;
    _qtyCtrl = TextEditingController(text: widget.leg.quantity.toString());
  }

  @override
  void didUpdateWidget(LegCard old) {
    super.didUpdateWidget(old);
    if (old.leg.quantity != widget.leg.quantity) {
      _qtyCtrl.text = widget.leg.quantity.toString();
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.leg.quantity > 0 ? Colors.green : Colors.red;
    final sign = widget.leg.quantity > 0 ? 'Long' : 'Short';

    return Card.outlined(
      // Clip content that overflows the shape
      clipBehavior: Clip.antiAlias,

      // Shove cards closer together to save space
      margin: const EdgeInsets.symmetric(vertical: cPaddingMini),

      // Card consists of a green/red C or P logo with short info and delete button
      // Tapping title or on 'v' expands controls (strike/quantity)
      child: Column(
        children: [
          ListTile(
            // Big colored letter in front
            leading: Text(
              widget.leg.type[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),

            // Expand button + short description
            title: Row(
              children: [
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                RichText(
                  text: TextSpan(
                    text:
                        // TODO: Nicer spacing info
                        '$sign ${widget.leg.quantity} ${widget.leg.type.toUpperCase()} @ ${widget.leg.strike.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: cMediumTextSize,
                    ),

                    // Also expand when tapping title (easier for mobile)
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        setState(() => _expanded = !_expanded);
                      },
                  ),
                ),
              ],
            ),

            // Delete button
            // TODO: maybe ask if user is sure? Although more smooth experience without...
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: widget.onDelete,
            ),
          ),

          if (_expanded)
            Padding(
              // Do not pad top to make card more compact
              padding: const EdgeInsets.only(
                left: cPaddingSmall,
                right: cPaddingSmall,
                bottom: cPaddingSmall,
              ),
              child: Column(
                children: [
                  // Move option leg left/right
                  _SliderRow(
                    label: 'Strike',
                    value: widget.leg.strike,
                    // FIXME: Do via ref
                    min: 50,
                    max: 150,
                    onChanged: (v) =>
                        widget.onChanged(widget.leg.copyWith(strike: v)),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(fontSize: cMediumTextSize),
                      ),

                      // Spacers to put quantity controls close to middle of top slider
                      // TODO: Something less hacky
                      SizedBox(width: 0.0),

                      // +/- constrols of number of options
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Decrement Button
                          IconButton(
                            icon: const Icon(Icons.remove, size: 24),
                            onPressed: () {
                              int currentQty =
                                  int.tryParse(_qtyCtrl.text) ??
                                  widget.leg.quantity;

                              // Can be negative
                              int newVal = (currentQty - 1).clamp(-cQuantLimit, cQuantLimit);
                              _qtyCtrl.text = newVal.toString();
                              widget.onChanged(
                                widget.leg.copyWith(quantity: newVal),
                              );
                            },
                          ),

                          // Editable Quantity Field
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // Only allow digits
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                border: const UnderlineInputBorder(),
                                hintText: '0',
                              ),
                              onSubmitted: (value) {
                                final int? newVal = int.tryParse(value);
                                if (newVal != null) {
                                  widget.onChanged(
                                    widget.leg.copyWith(quantity: newVal),
                                  );
                                }
                              },
                            ),
                          ),

                          // Increment Button
                          IconButton(
                            icon: const Icon(Icons.add, size: 24),
                            onPressed: () {
                              int currentQty =
                                  int.tryParse(_qtyCtrl.text) ??
                                  widget.leg.quantity;
                              int newVal = currentQty + 1;
                              _qtyCtrl.text = newVal.toString();
                              widget.onChanged(
                                widget.leg.copyWith(quantity: newVal),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(width: 0.0),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              child: Text('$label: ', style: const TextStyle(fontSize: 16)),
            ),

            // Editable Quantity Field
            SizedBox(
              width: 80,
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
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 2).toInt(),
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
