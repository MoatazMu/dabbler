import 'package:flutter/material.dart';

enum RatingCategory {
  overall,
  skill,
  sportsmanship,
  communication,
  teamwork,
  punctuality,
}

class PlayerRating {
  final RatingCategory category;
  final double rating;
  final String label;

  PlayerRating({
    required this.category,
    required this.rating,
    required this.label,
  });
}

class PlayerRatingWidget extends StatefulWidget {
  final String playerName;
  final String? playerAvatar;
  final List<RatingCategory> categories;
  final Function(List<PlayerRating>) onRatingSubmitted;
  final Function()? onSkipped;
  final Map<RatingCategory, double>? previousRatings;
  final bool showComments;
  final bool allowSkip;
  final bool showPreviousRatings;

  const PlayerRatingWidget({
    super.key,
    required this.playerName,
    this.playerAvatar,
    this.categories = const [RatingCategory.overall],
    required this.onRatingSubmitted,
    this.onSkipped,
    this.previousRatings,
    this.showComments = true,
    this.allowSkip = true,
    this.showPreviousRatings = true,
  });

  @override
  State<PlayerRatingWidget> createState() => _PlayerRatingWidgetState();
}

class _PlayerRatingWidgetState extends State<PlayerRatingWidget>
    with TickerProviderStateMixin {
  late Map<RatingCategory, double> _ratings;
  late TextEditingController _commentController;
  late AnimationController _submitAnimationController;
  late Animation<double> _submitAnimation;
  
  @override
  void initState() {
    super.initState();
    _ratings = {
      for (var category in widget.categories) category: 0.0
    };
    _commentController = TextEditingController();
    
    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _submitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _submitAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _submitAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlayerHeader(),
          const SizedBox(height: 24),
          _buildRatingCategories(),
          if (widget.showComments) ...[
            const SizedBox(height: 24),
            _buildCommentSection(),
          ],
          if (widget.showPreviousRatings && widget.previousRatings != null) ...[
            const SizedBox(height: 24),
            _buildPreviousRatings(),
          ],
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Player avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            backgroundImage: widget.playerAvatar != null
                ? NetworkImage(widget.playerAvatar!)
                : null,
            child: widget.playerAvatar == null
                ? Text(
                    widget.playerName.isNotEmpty
                        ? widget.playerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate Player',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.playerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How was their performance?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...widget.categories.map((category) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRatingCategory(category),
        )),
      ],
    );
  }

  Widget _buildRatingCategory(RatingCategory category) {
    final currentRating = _ratings[category] ?? 0.0;
    final categoryData = _getCategoryData(category);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentRating > 0 ? categoryData.color.withOpacity(0.3) : Colors.grey[300]!,
        ),
        boxShadow: currentRating > 0 ? [
          BoxShadow(
            color: categoryData.color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Icon(
                categoryData.icon,
                color: categoryData.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                categoryData.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            categoryData.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Star rating
          Row(
            children: [
              Expanded(
                child: _buildStarRating(category),
              ),
              if (currentRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryData.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: categoryData.color,
                    ),
                  ),
                ),
            ],
          ),
          
          // Rating description
          if (currentRating > 0) ...[
            const SizedBox(height: 8),
            Text(
              _getRatingDescription(currentRating),
              style: TextStyle(
                fontSize: 12,
                color: categoryData.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(RatingCategory category) {
    final currentRating = _ratings[category] ?? 0.0;
    
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isHalfStar = currentRating > index && currentRating < starValue;
        final isFilled = currentRating >= starValue;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _ratings[category] = starValue;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled || isHalfStar ? Icons.star : Icons.star_border,
              color: isFilled || isHalfStar ? Colors.amber : Colors.grey[400],
              size: 28,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share any specific feedback (optional)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Great teamwork! Always encouraging others...',
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousRatings() {
    if (widget.previousRatings == null || widget.previousRatings!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Previous Ratings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...widget.previousRatings!.entries.map((entry) {
            final categoryData = _getCategoryData(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    categoryData.icon,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryData.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < entry.value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasRatings = _ratings.values.any((rating) => rating > 0);
    
    return Column(
      children: [
        // Submit button
        AnimatedBuilder(
          animation: _submitAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _submitAnimation.value,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: hasRatings ? _submitRating : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Rating'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Skip button
        if (widget.allowSkip) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onSkipped,
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip Rating'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  ({IconData icon, String label, String description, Color color}) _getCategoryData(
      RatingCategory category) {
    switch (category) {
      case RatingCategory.overall:
        return (
          icon: Icons.star,
          label: 'Overall Rating',
          description: 'How would you rate this player overall?',
          color: Colors.amber,
        );
      case RatingCategory.skill:
        return (
          icon: Icons.sports,
          label: 'Skill Level',
          description: 'How skilled is this player at the sport?',
          color: Colors.blue,
        );
      case RatingCategory.sportsmanship:
        return (
          icon: Icons.handshake,
          label: 'Sportsmanship',
          description: 'How fair and respectful was their play?',
          color: Colors.green,
        );
      case RatingCategory.communication:
        return (
          icon: Icons.chat,
          label: 'Communication',
          description: 'How well did they communicate with the team?',
          color: Colors.purple,
        );
      case RatingCategory.teamwork:
        return (
          icon: Icons.group,
          label: 'Teamwork',
          description: 'How well did they work with the team?',
          color: Colors.orange,
        );
      case RatingCategory.punctuality:
        return (
          icon: Icons.schedule,
          label: 'Punctuality',
          description: 'Were they on time and reliable?',
          color: Colors.teal,
        );
    }
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Needs Improvement';
  }

  void _submitRating() {
    // Animate button
    _submitAnimationController.forward().then((_) {
      _submitAnimationController.reverse();
    });

    // Create rating list
    final ratings = _ratings.entries
        .where((entry) => entry.value > 0)
        .map((entry) => PlayerRating(
              category: entry.key,
              rating: entry.value,
              label: _getCategoryData(entry.key).label,
            ))
        .toList();

    // Submit ratings
    widget.onRatingSubmitted(ratings);
  }

  // Public methods for external control
  void setRating(RatingCategory category, double rating) {
    setState(() {
      _ratings[category] = rating.clamp(0.0, 5.0);
    });
  }

  void clearRatings() {
    setState(() {
      _ratings = {
        for (var category in widget.categories) category: 0.0
      };
      _commentController.clear();
    });
  }

  Map<RatingCategory, double> get currentRatings => Map.from(_ratings);
  String get comment => _commentController.text;
}
