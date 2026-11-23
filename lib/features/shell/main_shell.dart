import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'হোম'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'কুরআন'),
    (Icons.school_outlined, Icons.school_rounded, 'শিখি'),
    (Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'বুকমার্ক'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'প্রোফাইল'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final (icon, selected, label) in _items)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}
