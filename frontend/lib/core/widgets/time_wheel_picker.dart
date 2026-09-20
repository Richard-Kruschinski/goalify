import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Two scroll wheels - hours on the left, minutes on the right - in the style
/// of a native time picker: the centred value stands out, the neighbours fade
/// away, and both columns wrap around (23 -> 00, 59 -> 00).
class TimeWheelPicker extends StatefulWidget {
  const TimeWheelPicker({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    required this.onChanged,
    this.height = 176,
    this.itemExtent = 52,
  });

  /// Where the wheels start. Deliberately *initial* only: once mounted, the
  /// wheels are the sole owner of their position.
  ///
  /// Following the incoming values instead would fight the user's finger -
  /// [onChanged] triggers a rebuild of the surrounding screen, and pushing that
  /// value back into a wheel that is still spinning yanks it off course, so a
  /// fling lands somewhere other than where it was headed.
  final int initialHour;
  final int initialMinute;

  /// Fires once a wheel comes to rest - not on every value it flies past.
  final void Function(int hour, int minute) onChanged;

  final double height;
  final double itemExtent;

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  late int _hour;
  late int _minute;

  /// Last values handed to [TimeWheelPicker.onChanged].
  late int _committedHour;
  late int _committedMinute;

  // All four are assigned here rather than as `late` field initialisers: those
  // run on first *read*, which for the committed pair would be inside _commit()
  // - after the new value was already stored, so the first change would compare
  // equal to itself and be swallowed.
  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
    _committedHour = _hour;
    _committedMinute = _minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  // A tick per passed value keeps the wheel feeling mechanical.
  void _onHourPassed(int index) {
    final value = index % 24;
    if (value == _hour) return;
    _hour = value;
    HapticFeedback.selectionClick();
    _commit();
  }

  void _onMinutePassed(int index) {
    final value = index % 60;
    if (value == _minute) return;
    _minute = value;
    HapticFeedback.selectionClick();
    _commit();
  }

  /// Reports the current values, at most once per distinct pair.
  ///
  /// Called both when a wheel reports a new value and when it comes to rest:
  /// the two signals do not arrive in a fixed order, and relying on the scroll
  /// end alone loses the very first notch and then lags a step behind.
  /// De-duplicating here makes the double call free.
  void _commit() {
    if (_hour == _committedHour && _minute == _committedMinute) return;
    _committedHour = _hour;
    _committedMinute = _minute;
    widget.onChanged(_hour, _minute);
  }

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.ink(context);

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection band behind the wheels.
          Center(
            child: Container(
              height: widget.itemExtent,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.chip(context).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              _commit();
              return false;
            },
            child: Row(
              children: [
                Expanded(
                  child: _Wheel(
                    controller: _hourCtrl,
                    count: 24,
                    itemExtent: widget.itemExtent,
                    color: ink,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    onSelected: _onHourPassed,
                  ),
                ),
                SizedBox(
                  width: 16,
                  child: Text(
                    ':',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                Expanded(
                  child: _Wheel(
                    controller: _minuteCtrl,
                    count: 60,
                    itemExtent: widget.itemExtent,
                    color: ink,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 18),
                    onSelected: _onMinutePassed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One endless column of zero-padded numbers.
///
/// Built with an unbounded [ListWheelChildBuilderDelegate] rather than
/// [ListWheelChildLoopingListDelegate]: the looping delegate hands out the very
/// same widget instance for every repetition of a value, which makes the wheel
/// paint only part of its items. Building per index sidesteps that and gives
/// wrap-around in both directions for free (Dart's % is never negative).
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.itemExtent,
    required this.color,
    required this.alignment,
    required this.padding,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final int count;
  final double itemExtent;
  final Color color;
  final Alignment alignment;
  final EdgeInsets padding;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      physics: const FixedExtentScrollPhysics(),
      // Flutter's defaults - a flatter wheel exaggerates the perspective
      // squeeze on the outer rows until they are barely readable.
      diameterRatio: 2.0,
      perspective: 0.003,
      // Everything but the centred item fades - that alone marks the selection.
      overAndUnderCenterOpacity: 0.28,
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        // No childCount: the wheel runs endlessly in both directions.
        builder: (context, index) => Container(
          alignment: alignment,
          padding: padding,
          child: Text(
            (index % count).toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
