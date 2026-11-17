// Google Profile dashboard (website dashboard/Dashboard.jsx): six tabs shown on
// the Live screen once the profile is verified. Each tab loads its own data the
// first time it is opened and is then kept while another tab shows, so going
// back does not load it again. After the AI assistant changed something, the
// other tabs load again when next opened.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';
import 'improve_tab.dart';
import 'overview_tab.dart';
import 'photos_tab.dart';
import 'posts_tab.dart';
import 'profile_tab.dart';
import 'reviews_tab.dart';

class _TabDef {
  final String id;
  final String label;
  final IconData? icon;
  const _TabDef(this.id, this.label, [this.icon]);
}

const List<_TabDef> _tabs = [
  _TabDef('improve', 'Improve with AI', Icons.auto_awesome_outlined),
  _TabDef('overview', 'Overview'),
  _TabDef('reviews', 'Reviews'),
  _TabDef('posts', 'Posts'),
  _TabDef('profile', 'Profile'),
  _TabDef('photos', 'Photos'),
];

const String _storageKey = 'gp-dashboard-tab';

class GpDashboard extends StatefulWidget {
  final Map<String, dynamic> view;
  const GpDashboard({super.key, required this.view});

  @override
  State<GpDashboard> createState() => _GpDashboardState();
}

class _GpDashboardState extends State<GpDashboard> {
  String _active = 'improve';
  final List<String> _visited = ['improve'];
  List<String> _stale = [];
  final Map<String, int> _versions = {};
  final ScrollController _strip = ScrollController();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_storageKey);
      if (!mounted || id == null || !_tabs.any((t) => t.id == id)) return;
      _choose(id, remember: false);
    } catch (_) {
      // The remembered tab is a convenience only.
    }
  }

  void _onChanged() {
    setState(() {
      _stale = _tabs.map((t) => t.id).where((x) => x != 'improve').toList();
    });
  }

  void _choose(String id, {bool remember = true}) {
    setState(() {
      _active = id;
      if (!_visited.contains(id)) _visited.add(id);
      if (_stale.contains(id)) {
        _versions[id] = (_versions[id] ?? 0) + 1;
        _stale = _stale.where((x) => x != id).toList();
      }
    });
    if (remember) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_storageKey, id))
          .catchError((_) => false);
    }
  }

  Widget _panel(String id) {
    final key = ValueKey('$id-${_versions[id] ?? 0}');
    switch (id) {
      case 'improve':
        return GpImproveTab(
            key: key, view: widget.view, onOpenTab: _choose, onChanged: _onChanged);
      case 'overview':
        return GpOverviewTab(
            key: key, view: widget.view, onOpenTab: _choose, onChanged: _onChanged);
      case 'reviews':
        return GpReviewsTab(
            key: key, view: widget.view, onOpenTab: _choose, onChanged: _onChanged);
      case 'posts':
        return GpPostsTab(
            key: key, view: widget.view, onOpenTab: _choose, onChanged: _onChanged);
      case 'profile':
        return GpProfileTab(
            key: key, view: widget.view, onOpenTab: _choose, onChanged: _onChanged);
      case 'photos':
        return GpPhotosTab(
            key: key, view: widget.view, onOpenTab: _choose, onChanged: _onChanged);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _tabs.where((t) => _visited.contains(t.id)).toList();
    return Column(
      children: [
        Container(
          color: Colors.white,
          height: 48,
          child: ListView(
            controller: _strip,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final t in _tabs)
                _TabButton(
                  label: t.label,
                  icon: t.icon,
                  active: t.id == _active,
                  onTap: () => _choose(t.id),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: IndexedStack(
            index: shown.indexWhere((t) => t.id == _active),
            children: [
              for (final t in shown)
                KeyedSubtree(
                  key: ValueKey('panel-${t.id}'),
                  child: _panel(t.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: active ? AppColors.primary : Colors.transparent,
                  width: 2.5),
            ),
          ),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: color)),
          ]),
        ),
      ),
    );
  }
}
