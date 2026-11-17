// The per-day opening hours editor of the Profile tab (website
// dashboard/ProfileHoursEditor.jsx), used by opening hours and "more hours":
// each weekday is closed, or open with one or more opening–closing ranges.
// "24:00" (midnight) shows as 00:00.
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'profile_utils.dart';

class ProfileHoursEditor extends StatelessWidget {
  final String legend;
  final ProfileWeek value;
  final ValueChanged<ProfileWeek> onChanged;

  /// `{ "<prefix>mon.0": message }`.
  final Map<String, String> errors;
  final String prefix;

  const ProfileHoursEditor({
    super.key,
    required this.legend,
    required this.value,
    required this.onChanged,
    this.errors = const {},
    this.prefix = '',
  });

  void _setDay(String day, List<ProfileRange> ranges) {
    onChanged({...value, day: ranges});
  }

  @override
  Widget build(BuildContext context) {
    return GpStack(gap: 8, children: [
      Text(legend, style: GpText.h3),
      const Text('Closing at 00:00 means open until midnight.',
          style: GpText.note),
      for (final day in gpWeekdays) _day(day),
    ]);
  }

  Widget _day(GpWeekday day) {
    final ranges = value[day.id] ?? const <ProfileRange>[];
    final open = ranges.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
      decoration: BoxDecoration(
        color: open ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: GpStack(gap: 8, children: [
        Row(children: [
          Expanded(
            child: Text.rich(TextSpan(
                text: day.long,
                style: GpText.label,
                children: [
                  if (!open)
                    const TextSpan(text: ' · Closed', style: GpText.note),
                ])),
          ),
          const Text('Open', style: GpText.note),
          Switch(
            value: open,
            activeThumbColor: AppColors.primary,
            onChanged: (on) =>
                _setDay(day.id, on ? [ProfileRange()] : <ProfileRange>[]),
          ),
        ]),
        if (open) ...[
          for (var i = 0; i < ranges.length; i++) _range(day, ranges, i),
          Align(
            alignment: Alignment.centerLeft,
            child: GpButton.ghost(
              label: 'Add hours',
              icon: Icons.add,
              small: true,
              onPressed: () =>
                  _setDay(day.id, [...ranges, ProfileRange()]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _range(GpWeekday day, List<ProfileRange> ranges, int i) {
    final r = ranges[i];
    final error = errors['$prefix${day.id}.$i'];
    void update({String? open, String? close}) {
      _setDay(day.id, [
        for (var j = 0; j < ranges.length; j++)
          j == i
              ? ProfileRange(
                  open: open ?? ranges[j].open,
                  close: close ?? ranges[j].close)
              : ranges[j],
      ]);
    }

    return GpStack(gap: 4, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: GpTimeField(
            label: 'Opens',
            value: r.open,
            onChanged: (v) => update(open: v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GpTimeField(
            label: 'Closes',
            value: r.close == '24:00' ? '00:00' : r.close,
            onChanged: (v) => update(close: v == '00:00' ? '24:00' : v),
          ),
        ),
        IconButton(
          tooltip: 'Remove these hours on ${day.long}',
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => _setDay(day.id, [
            for (var j = 0; j < ranges.length; j++)
              if (j != i) ranges[j],
          ]),
        ),
      ]),
      if (error != null) Text(error, style: GpText.error),
    ]);
  }
}
