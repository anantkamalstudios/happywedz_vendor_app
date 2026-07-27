import 'package:flutter/material.dart';

mixin FacilitiesHelpersMixin<T extends StatefulWidget> on State<T> {
  static const Color kHeaderBg   = Color(0xFFDDE8F8);
  static const Color kAccentBlue = Color(0xFF00509D);

  Map<String, dynamic> asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  List<String> toList(dynamic v) =>
      v is List ? List<String>.from(v) : [];

  Widget sectionHeader(String title, bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kHeaderBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget buildDropdown(
    String label,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final safe = options.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: DropdownButton<String>(
            value: safe,
            isExpanded: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(10),
            items: options
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget buildMultiSelect(
    String label,
    List<String> options,
    List<String> selected,
    void Function(String, bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        Wrap(
          children: options.map((opt) {
            final checked = selected.contains(opt);
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 32) / 2,
              child: Row(
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: (v) => onChanged(opt, v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    activeColor: kAccentBlue,
                  ),
                  Expanded(child: Text(opt, style: const TextStyle(fontSize: 12))),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // Dropdown with an appended "Other" option; reveals a free-text field when
  // "Other" is selected, written to [otherCtrl].
  Widget buildDropdownWithOther(
    String label,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged,
    TextEditingController otherCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildDropdown(label, [...options, "Other"], value, onChanged),
        if (value == "Other")
          buildTextArea("$label — please specify", otherCtrl, maxLines: 1),
      ],
    );
  }

  // Multi-select with an appended "Other" option; reveals a free-text field
  // when "Other" is selected, written to [otherCtrl].
  Widget buildMultiSelectWithOther(
    String label,
    List<String> options,
    List<String> selected,
    void Function(String, bool) onChanged,
    TextEditingController otherCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildMultiSelect(label, [...options, "Other"], selected, onChanged),
        if (selected.contains("Other"))
          buildTextArea("$label — please specify", otherCtrl, maxLines: 1),
      ],
    );
  }

  Widget buildYesNo(String label, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        RadioGroup<String>(
          groupValue: value,
          onChanged: onChanged,
          child: Row(
            children: ['Yes', 'No']
                .map((opt) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: opt,
                          activeColor: kAccentBlue,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text(opt, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget buildNumberField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: inputDec(),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget buildTextArea(String label, TextEditingController ctrl, {int maxLines = 4}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        TextField(controller: ctrl, maxLines: maxLines, decoration: inputDec()),
        const SizedBox(height: 18),
      ],
    );
  }

  InputDecoration inputDec() => InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget dividerLine() =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider());
}
