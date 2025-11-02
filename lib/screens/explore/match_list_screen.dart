import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../themes/app_theme.dart';
import '../../features/games/providers/games_providers.dart';
import '../../features/games/domain/entities/game.dart';
import '../../features/games/presentation/screens/join_game/game_detail_screen.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  final String sport;
  final Color sportColor;
  final String searchQuery;

  const MatchListScreen({
    super.key,
    required this.sport,
    required this.sportColor,
    this.searchQuery = '',
  });

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // Watch the public games provider
    final publicGamesAsync = ref.watch(publicGamesProvider);

    return publicGamesAsync.when(
      data: (allGames) {
        print('🎮 [DEBUG] Public games loaded: ${allGames.length} games');

        // Filter by sport
        final sportFilteredGames = allGames.where((game) {
          return game.sport.toLowerCase() == widget.sport.toLowerCase();
        }).toList();

        print(
          '🎮 [DEBUG] After sport filter (${widget.sport}): ${sportFilteredGames.length} games',
        );

        // Filter by search query if any
        final searchFilteredGames = widget.searchQuery.isEmpty
            ? sportFilteredGames
            : sportFilteredGames.where((game) {
                return game.title.toLowerCase().contains(
                      widget.searchQuery.toLowerCase(),
                    ) ||
                    game.description.toLowerCase().contains(
                      widget.searchQuery.toLowerCase(),
                    );
              }).toList();

        print(
          '🎮 [DEBUG] After search filter: ${searchFilteredGames.length} games',
        );

        if (searchFilteredGames.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.gamepad2,
                  size: 64,
                  color: context.colors.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${widget.sport} games found',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to create one!',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filters
            _buildFilters(),

            // Game list - display directly as Game entities
            Expanded(child: _buildGamesList(searchFilteredGames)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        print('❌ [ERROR] Failed to load public games: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load games', style: context.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(publicGamesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build games list from Game entities (no conversion needed)
  Widget _buildGamesList(List<Game> games) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(game);
      },
    );
  }

  /// Build a game card from Game entity
  Widget _buildGameCard(Game game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(game.title),
        subtitle: Text(
          '${game.scheduledDate.toString().split(' ')[0]} • ${game.startTime} - ${game.endTime}\n'
          '${game.currentPlayers}/${game.maxPlayers} players • ${game.currency} ${game.pricePerPlayer.toStringAsFixed(0)}',
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: widget.sportColor),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GameDetailScreen(gameId: game.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    final filters = _getFiltersForSport();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text(
          //   '${widget.sport} Games',
          //   style: context.textTheme.titleLarge?.copyWith(
          //     fontWeight: FontWeight.w700,
          //     color: context.colors.onSurface,
          //   ),
          // ),
          // Text(
          //   _getSportDescription(),
          //   style: context.textTheme.bodyMedium?.copyWith(
          //     color: context.colors.onSurfaceVariant,
          //   ),
          // ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: filters.map((filter) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: filter != filters.last ? 8 : 0,
                    ),
                    child: _buildFilterChip(
                      filter['label'] ?? '',
                      filter['value'] ?? '',
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFiltersForSport() {
    switch (widget.sport.toLowerCase()) {
      case 'football':
        return [
          {'label': 'All', 'value': 'all'},
          {'label': 'Futsal', 'value': 'futsal'},
          {'label': 'Competitive', 'value': 'competitive'},
          {'label': 'Substitutional', 'value': 'substitutional'},
          {'label': 'Association', 'value': 'association'},
          {'label': 'Free', 'value': 'free'},
          {'label': 'Today', 'value': 'today'},
        ];
      case 'cricket':
        return [
          {'label': 'All', 'value': 'all'},
          {'label': 'T20', 'value': 't20'},
          {'label': 'ODI', 'value': 'odi'},
          {'label': 'Test', 'value': 'test'},
          {'label': 'Practice', 'value': 'practice'},
          {'label': 'Free', 'value': 'free'},
          {'label': 'Today', 'value': 'today'},
        ];
      case 'padel':
        return [
          {'label': 'All', 'value': 'all'},
          {'label': 'Singles', 'value': 'singles'},
          {'label': 'Doubles', 'value': 'doubles'},
          {'label': 'Free', 'value': 'free'},
          {'label': 'Today', 'value': 'today'},
        ];
      default:
        return [
          {'label': 'All', 'value': 'all'},
          {'label': 'Free', 'value': 'free'},
          {'label': 'Today', 'value': 'today'},
        ];
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        // Filter will be applied automatically when publicGamesProvider rebuilds
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.sportColor : context.violetWidgetBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? widget.sportColor
                : context.colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}
