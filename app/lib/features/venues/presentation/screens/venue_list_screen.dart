import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/features/auth/providers/auth_provider.dart';
import 'package:quickslot/features/venues/domain/entities/venue_entity.dart';
import 'package:quickslot/features/venues/presentation/providers/venue_provider.dart';

// ----- Sport-specific Unsplash photos (stable direct photo IDs) -----
// Format: images.unsplash.com/photo-{id} — no query hotlinking, works on Android
//
// Badminton courts — actual court photography
const _badmintonImages = [
  'https://images.unsplash.com/photo-1637666062717-1c6bcfa4a4df?w=640&q=75&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=640&q=75&auto=format&fit=crop',
];
// Turf / football pitches
const _turfImages = [
  'https://images.unsplash.com/photo-1431324155629-1a6ddc1dec79?w=640&q=75&auto=format&fit=crop',
  'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=640&q=75&auto=format&fit=crop',
];

String _imageFor(VenueEntity v) {
  final list = v.sportType == 'turf' ? _turfImages : _badmintonImages;
  // Distribute across venues of same type using the venue id
  return list[v.id % list.length];
}

class VenueListScreen extends ConsumerWidget {
  const VenueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venueListProvider);
    final userId = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      // Pinned app bar — never scrolls away
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'QuickSlot',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            iconSize: 22,
            tooltip: 'My Bookings',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(Routes.myBookings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            iconSize: 22,
            tooltip: 'Log out',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(authProvider.notifier).logout();
              context.go(Routes.userSelect);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Greeting section — scrolls away with content, that's fine
          SliverToBoxAdapter(
            child: _Greeting(userId: userId),
          ),
          // Venue list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: venuesAsync.when(
              loading: () => SliverList.builder(
                itemCount: 3,
                itemBuilder: (context, index) => const _VenueCardSkeleton(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorView(onRetry: () => ref.invalidate(venueListProvider)),
              ),
              data: (venues) => venues.isEmpty
                  ? const SliverFillRemaining(child: _EmptyView())
                  : SliverList.separated(
                      itemCount: venues.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 20),
                      itemBuilder: (_, i) => _VenueCard(venue: venues[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.userId});
  final String? userId;

  String _firstName(String? id) {
    switch (id) {
      case 'user-001': return 'Arjun';
      case 'user-002': return 'Priya';
      case 'user-003': return 'Rahul';
      default: return 'there';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to play, ${_firstName(userId)}?',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Book a sports venue near you — instantly.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue});
  final VenueEntity venue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = _imageFor(venue);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/venues/${venue.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerTheme.color!),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            SizedBox(
              height: 175,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _Shimmer();
                },
                errorBuilder: (context, error, stackTrace) =>
                    _SportFallback(sportType: venue.sportType),
              ),
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                venue.location,
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            venue.sportType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${venue.priceInr}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            TextSpan(
                              text: ' /hr',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        color: Color.lerp(const Color(0xFFEAEAE6), const Color(0xFFF5F5F1), _anim.value),
      ),
    );
  }
}

class _SportFallback extends StatelessWidget {
  const _SportFallback({required this.sportType});
  final String sportType;

  @override
  Widget build(BuildContext context) {
    // Richer sport-tinted backgrounds so fallback cards don't blend with white
    final bg = sportType == 'turf'
        ? const Color(0xFFCEE5C8)  // grass green
        : const Color(0xFFBFD9E8); // court blue
    final emoji = sportType == 'turf' ? '⚽' : '🏸';
    return Container(
      color: bg,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 52))),
    );
  }
}

class _VenueCardSkeleton extends StatelessWidget {
  const _VenueCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerTheme.color!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 175, color: const Color(0xFFEEEEEB)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 15, width: 150, decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEB), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 12, width: 100, decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEB), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Could not connect', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Check your network and try again.',
                style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No venues listed yet.', style: TextStyle(color: Colors.grey)));
  }
}
