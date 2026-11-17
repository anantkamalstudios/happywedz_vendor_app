// A search box with Google's answers under it (website dashboard/ProfileSearch.jsx),
// for the Profile tab's Categories (categories) and Service area (places).
// Searches after 2 letters and a short pause; older answers are ignored.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_parts.dart';

class ProfileSearch extends StatefulWidget {
  final String label;
  final Future<dynamic> Function(String q) search;
  final String Function(Map<String, dynamic> item) itemTitle;
  final String Function(Map<String, dynamic> item)? itemSub;
  final Widget Function(Map<String, dynamic> item) buildActions;
  final bool disabled;
  final String emptyText;

  const ProfileSearch({
    super.key,
    required this.label,
    required this.search,
    required this.itemTitle,
    required this.buildActions,
    required this.emptyText,
    this.itemSub,
    this.disabled = false,
  });

  @override
  State<ProfileSearch> createState() => _ProfileSearchState();
}

class _ProfileSearchState extends State<ProfileSearch> {
  final TextEditingController _text = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int _request = 0;

  // Result of the last search.
  String _resultQuery = '';
  String _status = 'idle'; // idle | loading | ready | error
  List<Map<String, dynamic>> _items = const [];
  Object? _error;

  @override
  void didUpdateWidget(covariant ProfileSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disabled && !widget.disabled) _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onText(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final q = value.trim();
      if (q == _query) return;
      setState(() => _query = q);
      _run();
    });
  }

  Future<void> _run() async {
    final query = _query;
    if (query.length < 2 || widget.disabled) return;
    final mine = ++_request;
    setState(() {
      _resultQuery = query;
      _status = 'loading';
      _items = const [];
      _error = null;
    });
    try {
      final data = await widget.search(query);
      if (!mounted || mine != _request) return;
      setState(() {
        _status = 'ready';
        _items = data is List
            ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : const [];
      });
    } catch (e) {
      if (!mounted || mine != _request) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _status = 'error';
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active =
        _query.length >= 2 && !widget.disabled && _resultQuery == _query;
    return GpStack(gap: 6, children: [
      Text(widget.label, style: GpText.label),
      TextField(
        controller: _text,
        enabled: !widget.disabled,
        onChanged: _onText,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        style: const TextStyle(fontSize: 14),
        decoration: gpInputDecoration(
          helper: 'Type at least 2 letters.',
          prefixIcon: const Icon(Icons.search, size: 20),
        ),
      ),
      if (active && _status == 'loading') const GpLoadingLine('Searching…'),
      if (active && _status == 'error')
        Text(
            gpErrorMessage(
                _error, "The search didn't work. Please try again."),
            style: GpText.error),
      if (active && _status == 'ready' && _items.isEmpty)
        Text(widget.emptyText, style: GpText.note),
      if (active && _status == 'ready' && _items.isNotEmpty)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 140),
                      child: GpStack(gap: 2, children: [
                        Text(widget.itemTitle(_items[i]),
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary)),
                        if ((widget.itemSub?.call(_items[i]) ?? '').isNotEmpty)
                          Text(widget.itemSub!(_items[i]), style: GpText.note),
                      ]),
                    ),
                    widget.buildActions(_items[i]),
                  ],
                ),
              ),
            ],
          ]),
        ),
    ]);
  }
}
