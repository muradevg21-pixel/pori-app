import 'package:material_ui/material_ui.dart';

import '../../core/widgets/common.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('বুকমার্ক')),
        body: const EmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'এখনও কোনো বুকমার্ক নেই',
          message: 'পড়ার সময় আয়াতে বুকমার্ক চিহ্ন দিলে\nতা এখানে দেখা যাবে।',
        ),
      );
}
