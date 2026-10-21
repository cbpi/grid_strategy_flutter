import 'package:flutter/material.dart';

class AppFeatureDrawer extends StatelessWidget {
  const AppFeatureDrawer({super.key, required this.selectedRoute});

  final String selectedRoute;

  static const _items = [
    _FeatureItem('/grid', '网格策略', Icons.grid_view_rounded),
    _FeatureItem('/turnover', '换手率选股', Icons.query_stats_rounded),
    _FeatureItem('/averaging', '补仓计算', Icons.calculate_outlined),
  ];

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    selectedIndex: _items.indexWhere((item) => item.route == selectedRoute),
    onDestinationSelected: (index) {
      final item = _items[index];
      if (item.route == selectedRoute) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(item.route, (_) => false);
    },
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 16, 12),
        child: Text(
          '股票工具',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      for (final item in _items)
        NavigationDrawerDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        ),
    ],
  );
}

class _FeatureItem {
  const _FeatureItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}
