import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickslot/core/router/app_router.dart';
import 'package:quickslot/features/auth/providers/auth_provider.dart';
import 'package:quickslot/features/venues/domain/entities/venue_entity.dart';
import 'package:quickslot/features/venues/presentation/providers/venue_provider.dart';

class VenueListScreen extends ConsumerWidget {
  const VenueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venueListProvider);
    final userId = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // gradient header
          SliverToBoxAdapter(child: _Header(userId: userId, ref: ref)),
          // content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: venuesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorView(
                  onRetry: () => ref.invalidate(venueListProvider),
                ),
              ),
              data: (venues) => venues.isEmpty
                  ? const SliverFillRemaining(child: _EmptyView())
                  : SliverList.separated(
                      itemCount: venues.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _VenueCard(venue: venues[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

}

class _Header extends StatelessWidget {
  const _Header({required this.userId, required this.ref});
  final String? userId;
  final WidgetRef ref;

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111520), Color(0xFF0D0F14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // logo mark
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C896), Color(0xFF00A67C)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'QuickSlot',
                    style: TextStyle(
                      color: Color(0xFFF0F4FF),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // bookings icon
                  _ActionButton(
                    icon: Icons.bookmark_rounded,
                    onTap: () => context.push(Routes.myBookings),
                    tooltip: 'My Bookings',
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.logout_rounded,
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go(Routes.userSelect);
                    },
                    tooltip: 'Switch user',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Hey ${_firstName(userId)} 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF0F4FF),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pick a venue and book your slot',
                style: TextStyle(fontSize: 14, color: Color(0xFF8B95B0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2F3E)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF8B95B0)),
        ),
      ),
    );
  }
}

class _VenueCard extends StatefulWidget {
  const _VenueCard({required this.venue});
  final VenueEntity venue;

  @override
  State<_VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<_VenueCard> {
  bool _pressed = false;

  static const _sportGradients = {
    'badminton': [Color(0xFF00C896), Color(0xFF00A67C)],
    'turf': [Color(0xFF4F8EF7), Color(0xFF2E6FE0)],
  };

  @override
  Widget build(BuildContext context) {
    final gradColors = _sportGradients[widget.venue.sportType] ??
        [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push('/venues/${widget.venue.id}'),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2230),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2F3E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // sport banner
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradColors.map((c) => c.withValues(alpha: 0.25)).toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      bottom: 8,
                      child: Text(
                        widget.venue.sportEmoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: gradColors[0].withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: gradColors[0].withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          widget.venue.sportType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: gradColors[0],
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.venue.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF0F4FF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: Color(0xFF8B95B0),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.venue.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B95B0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradColors),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradColors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '₹${widget.venue.priceInr}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
                            'per hr',
                            style: TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A2F3E)),
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 32, color: Color(0xFF8B95B0)),
            ),
            const SizedBox(height: 16),
            const Text('Could not load venues',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF0F4FF))),
            const SizedBox(height: 8),
            const Text('Check your connection and try again',
                style: TextStyle(fontSize: 13, color: Color(0xFF8B95B0)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏟️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('No venues found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF0F4FF))),
        ],
      ),
    );
  }
}
