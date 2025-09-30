import 'package:flutter/material.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({Key? key}) : super(key: key);

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final List<int> _ratingFilters = [0, 5, 4, 3, 2, 1];
  int _selectedFilter = 0;
  final List<Review> _allReviews = [
    Review(
      reviewer: 'Neha Singh',
      rating: 5,
      date: DateTime(2025, 7, 15),
      text: 'Absolutely loved their work—it was flawless from start to finish!',
    ),
    Review(
      reviewer: 'Rohan Jain',
      rating: 4,
      date: DateTime(2025, 6, 21),
      text: 'Very professional and creative, but the decor budget felt a bit high.',
    ),
    Review(
      reviewer: 'Priya & Amit',
      rating: 5,
      date: DateTime(2025, 5, 10),
      text: 'Best decision ever! The wedding looked magical. Thank you!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 0
        ? _allReviews
        : _allReviews.where((r) => r.rating == _selectedFilter).toList();

    final averageRating = _allReviews.isEmpty
        ? 0.0
        : _allReviews.map((r) => r.rating).reduce((a, b) => a + b) / _allReviews.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildSummary(averageRating, _allReviews.length)),
          // SliverToBoxAdapter(child: _buildFilterChips()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                final r = filtered[idx];
                return _buildReviewCard(r);
              },
              childCount: filtered.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 50,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffff4d79), Color(0xffff6faf)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 16),
        alignment: Alignment.bottomLeft,
        child: const Text(
          'Reviews',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(double avgRating, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Text(
            'Reviews',
            style: TextStyle(fontSize: 18),
          ),
          const Spacer(),
          Row(
            children: [
              Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildFilterChips() {
  //   return SizedBox(
  //     height: 40,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       itemCount: _ratingFilters.length,
  //       itemBuilder: (ctx, i) {
  //         final val = _ratingFilters[i];
  //         final label = val == 0 ? 'All' : '$val ⭐';
  //         final selected = _selectedFilter == val;
  //         return Padding(
  //           padding: const EdgeInsets.only(right: 8),
  //           child: ChoiceChip(
  //             label: Text(label),
  //             selected: selected,
  //             onSelected: (_) => setState(() => _selectedFilter = val),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildReviewCard(Review r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(r.reviewer[0], style: const TextStyle(color: Colors.black87)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(r.reviewer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Text(
              _fmtDate(r.date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) {
            return Icon(
              i < r.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          })),
          const SizedBox(height: 8),
          Text(r.text, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {/* Reply logic */},
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Reply'),
              ),
            ],
          )
        ]),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class Review {
  final String reviewer;
  final int rating;
  final DateTime date;
  final String text;

  Review({
    required this.reviewer,
    required this.rating,
    required this.date,
    required this.text,
  });
}
