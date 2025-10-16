import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/games_providers.dart';
import '../../../../../core/services/auth_service.dart';

class GameDetailScreen extends ConsumerStatefulWidget {
  final String gameId;
  
  const GameDetailScreen({
    super.key,
    required this.gameId,
  });

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> 
    with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late ScrollController _scrollController;
  bool _isJoined = false;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUserId = authService.getCurrentUserId();
    
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view game details')),
      );
    }
    
    final detailState = ref.watch(
      gameDetailControllerProvider(
        GameDetailParams(
          gameId: widget.gameId,
          currentUserId: currentUserId,
        ),
      ),
    );
    
    if (detailState.isLoading || !detailState.hasGame) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (detailState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${detailState.error}'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    final game = detailState.game!;
    
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(game),
          _buildGameContent(game, detailState),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(game, detailState),
    );
  }

  Widget _buildSliverAppBar(dynamic game) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      title: AnimatedOpacity(
        opacity: _showAppBarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Text('Game Details'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image
            Hero(
              tag: 'game-${widget.gameId}',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[400]!,
                      Colors.blue[600]!,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.sports,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Game Info Overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          game.sport.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'INTERMEDIATE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareGame,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildGameContent(dynamic game, dynamic detailState) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildQuickInfo(game),
          _buildGameDescription(),
          _buildPlayersSection(),
          _buildVenueSection(),
          _buildOrganizerSection(),
          _buildCommentsSection(),
          const SizedBox(height: 100), // Bottom padding for sticky bar
        ],
      ),
    );
  }

  Widget _buildQuickInfo(dynamic game) {
    final dateFormat = DateFormat('EEEE, MMM dd');
    final formattedDate = dateFormat.format(game.scheduledDate);
    
    return Consumer(
      builder: (context, ref, child) {
        final detailState = ref.watch(gameDetailControllerProvider(
          GameDetailParams(gameId: widget.gameId, currentUserId: null)
        ));
        
        final venue = detailState.venue;
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date and Time
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${game.startTime} - ${game.endTime}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Location
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue?.name ?? 'Venue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              venue != null 
                                ? '${venue.addressLine1}, ${venue.city}' 
                                : 'Address not available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showDirections,
                        child: const Text('Directions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.monetization_on, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.pricePerPlayer > 0 
                                ? '${game.currency} ${game.pricePerPlayer.toStringAsFixed(0)}' 
                                : 'Free to Play',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              game.pricePerPlayer > 0 
                                ? 'Per player' 
                                : 'No cost per player',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameDescription() {
    return Consumer(
      builder: (context, ref, child) {
        final detailState = ref.watch(gameDetailControllerProvider(
          GameDetailParams(gameId: widget.gameId, currentUserId: null)
        ));
        
        final game = detailState.game;
        if (game == null) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.description,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  
                  // Game Rules/Requirements
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange[700], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Game Requirements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('• ${game.skillLevel} skill level'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersSection() {
    return Consumer(
      builder: (context, ref, child) {
        final detailState = ref.watch(gameDetailControllerProvider(
          GameDetailParams(gameId: widget.gameId, currentUserId: null)
        ));
        
        final game = detailState.game;
        if (game == null) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Players (${game.currentPlayers}/${game.maxPlayers})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _viewAllPlayers,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Players List Preview
                  ...List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[300],
                            child: Text('P${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Player ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Intermediate • ${20 + index * 5} games played',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (index == 0) // Organizer
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ORGANIZER',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (game.currentPlayers < game.maxPlayers) // Still spots available
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            '${game.maxPlayers - game.currentPlayers} ${game.maxPlayers - game.currentPlayers == 1 ? 'spot' : 'spots'} still available!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
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
      },
    );
  }

  Widget _buildVenueSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.place, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Venue Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _viewVenue,
                    child: const Text('View Venue'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Venue Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              
              const Text(
                'Central Park Basketball Court',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '123 Main Street, New York, NY 10001',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              
              // Venue Features
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: const Text('Free Parking'),
                    backgroundColor: Colors.green[100],
                  ),
                  Chip(
                    label: const Text('Restrooms'),
                    backgroundColor: Colors.blue[100],
                  ),
                  Chip(
                    label: const Text('Water Fountain'),
                    backgroundColor: Colors.cyan[100],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Organizer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[300],
                    child: const Text('JD', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'John Doe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organizes 2-3 games per week',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                size: 16,
                                color: index < 4 ? Colors.amber : Colors.grey[300],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('4.8 (24 reviews)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _messageOrganizer,
                        icon: const Icon(Icons.message),
                        tooltip: 'Message',
                      ),
                      IconButton(
                        onPressed: _viewOrganizerProfile,
                        icon: const Icon(Icons.person),
                        tooltip: 'Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.comment, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Comments (3)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _addComment,
                    child: const Text('Add Comment'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Sample Comments
              ...List.generate(
                2,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: Text('U${index + 1}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'User ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '2h ago',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              index == 0 
                                ? 'Looking forward to this game! Should be fun.'
                                : 'Will there be extra balls available?',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(dynamic game, dynamic detailState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free to Play',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tomorrow at 6:00 PM',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Join/Leave Button
            SizedBox(
              width: 120,
              height: 48,
              child: ElevatedButton(
                onPressed: _isJoined ? _leaveGame : _joinGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isJoined ? Colors.red : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  _isJoined ? 'Leave' : 'Join Game',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing game...')),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report Game'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Save Game'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Add to Calendar'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDirections() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening directions...')),
    );
  }

  void _viewAllPlayers() {
    print('Viewing all players');
  }

  void _viewVenue() {
    Navigator.pushNamed(context, '/venues/detail', arguments: 'venue-id');
  }

  void _messageOrganizer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening message...')),
    );
  }

  void _viewOrganizerProfile() {
    print('Viewing organizer profile');
  }

  void _addComment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Type your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _joinGame() {
    setState(() {
      _isJoined = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully joined the game!')),
    );
  }

  void _leaveGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isJoined = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You have left the game')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
