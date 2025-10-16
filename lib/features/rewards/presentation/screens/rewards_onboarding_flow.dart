import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RewardsOnboardingFlow extends ConsumerStatefulWidget {
  const RewardsOnboardingFlow({super.key});

  @override
  ConsumerState<RewardsOnboardingFlow> createState() => _RewardsOnboardingFlowState();
}

class _RewardsOnboardingFlowState extends ConsumerState<RewardsOnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _confettiController;
  
  int _currentPage = 0;
  final int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Skip'),
                  ),
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _totalPages,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 16,
                      activeDotColor: Colors.deepPurple,
                      dotColor: Colors.grey[300]!,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the skip button
                ],
              ),
            ),
            
            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                children: [
                  _buildWelcomePage(),
                  _buildFirstAchievementPage(),
                  _buildPointsExplanationPage(),
                  _buildTierSystemPage(),
                  _buildBadgeCollectionPage(),
                  _buildDailyEngagementPage(),
                ],
              ),
            ),
            
            // Navigation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 48),
                  
                  ElevatedButton(
                    onPressed: _currentPage < _totalPages - 1 ? _nextPage : _finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated trophy icon
                  ScaleTransition(
                    scale: Tween(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.amber, Colors.orange],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Welcome to Rewards!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Earn points, unlock achievements, and climb the leaderboard as you explore and engage with Dabbler.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Feature preview cards
                  Row(
                    children: [
                      Expanded(child: _buildPreviewCard(Icons.stars, 'Achievements', Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPreviewCard(Icons.trending_up, 'Points', Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPreviewCard(Icons.military_tech, 'Tiers', Colors.purple)),
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

  Widget _buildFirstAchievementPage() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Achievement unlock animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.amber.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Achievement badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Your First Achievement!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Achievement details card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.amber[50]!, Colors.orange[50]!],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Aboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Complete your first onboarding',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '+100 Points',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Achievements are special milestones you unlock by completing various activities in Dabbler.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPointsExplanationPage() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Points animation
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.cyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '1,250',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'POINTS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'How Points Work',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Points sources
                  ..._buildPointsSourceCards([
                    {'icon': Icons.sports_esports, 'title': 'Playing Games', 'points': '+50', 'color': Colors.green},
                    {'icon': Icons.people, 'title': 'Social Actions', 'points': '+25', 'color': Colors.orange},
                    {'icon': Icons.emoji_events, 'title': 'Achievements', 'points': '+100', 'color': Colors.purple},
                    {'icon': Icons.calendar_today, 'title': 'Daily Login', 'points': '+20', 'color': Colors.blue},
                  ]),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Points unlock new tiers, achievements, and special rewards. Keep earning to climb higher!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierSystemPage() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tier System',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Advance through tiers to unlock multipliers and exclusive features',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Tier progression visualization
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTierRow('Diamond', Icons.diamond, Colors.cyan, '50,000+', '2.0x', false),
                        _buildTierRow('Platinum', Icons.military_tech, Colors.blue[200]!, '15,000', '1.8x', false),
                        _buildTierRow('Gold', Icons.star, Colors.amber, '5,000', '1.5x', false),
                        _buildTierRow('Silver', Icons.stars, Colors.grey, '1,000', '1.2x', false),
                        _buildTierRow('Bronze', Icons.emoji_events, Colors.brown, '0', '1.0x', true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Higher tiers give you more points for every action!',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildBadgeCollectionPage() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Badge Collection',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Collect beautiful badges for your achievements',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Badge showcase
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Badge Collection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Badge grid
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildBadgeItem(Icons.star, Colors.amber, true),
                            _buildBadgeItem(Icons.favorite, Colors.red, false),
                            _buildBadgeItem(Icons.sports_esports, Colors.blue, false),
                            _buildBadgeItem(Icons.explore, Colors.green, false),
                            _buildBadgeItem(Icons.people, Colors.orange, false),
                            _buildBadgeItem(Icons.flash_on, Colors.yellow, false),
                            _buildBadgeItem(Icons.trending_up, Colors.purple, false),
                            _buildBadgeItem(Icons.emoji_events, Colors.cyan, false),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          '1/8 Badges Earned',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Badges showcase your unique accomplishments and can be displayed on your profile!',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildDailyEngagementPage() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Streak flame animation
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 50,
                          color: Colors.white,
                        ),
                        Text(
                          '7 DAY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Daily Engagement Tips',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Build streaks and maximize your rewards!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Daily tips
                  ..._buildDailyTipCards([
                    {
                      'icon': Icons.calendar_today,
                      'title': 'Daily Login',
                      'description': 'Log in every day for bonus points and streak rewards',
                      'color': Colors.blue,
                    },
                    {
                      'icon': Icons.local_fire_department,
                      'title': 'Maintain Streaks',
                      'description': 'Consecutive actions unlock multiplier bonuses',
                      'color': Colors.red,
                    },
                    {
                      'icon': Icons.explore,
                      'title': 'Explore Features',
                      'description': 'Try different parts of the app for variety bonuses',
                      'color': Colors.green,
                    },
                  ]),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.green[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Small daily actions lead to big rewards over time!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildPreviewCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPointsSourceCards(List<Map<String, dynamic>> sources) {
    return sources.map((source) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: source['color'].withOpacity(0.1),
            ),
            child: Icon(
              source['icon'],
              color: source['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              source['title'],
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            source['points'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: source['color'],
            ),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildTierRow(String name, IconData icon, Color color, String requirement, String multiplier, bool current) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: current ? color.withOpacity(0.1) : Colors.transparent,
        border: current ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: current ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            requirement,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            multiplier,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (current) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle, color: color, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, Color color, bool earned) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? color : Colors.grey[300],
        boxShadow: earned ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Icon(
        icon,
        color: earned ? Colors.white : Colors.grey[500],
        size: 24,
      ),
    );
  }

  List<Widget> _buildDailyTipCards(List<Map<String, dynamic>> tips) {
    return tips.map((tip) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tip['color'].withOpacity(0.1),
            ),
            child: Icon(
              tip['icon'],
              color: tip['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['description'],
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
    )).toList();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    Navigator.of(context).pop();
    // Mark onboarding as completed
    ref.read(onboardingProvider.notifier).completeOnboarding();
  }

  void _finishOnboarding() {
    // Trigger confetti animation
    _confettiController.forward();
    
    // Award first achievement
    ref.read(rewardsProvider.notifier).awardFirstAchievement();
    
    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Welcome Aboard!'),
        content: const Text(
          'You\'ve earned your first achievement and 100 points! '
          'Start exploring Dabbler to unlock more rewards.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close onboarding
              ref.read(onboardingProvider.notifier).completeOnboarding();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Let\'s Go!'),
          ),
        ],
      ),
    );
  }
}

// Providers
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false);

  void completeOnboarding() {
    state = true;
    // Save to persistent storage
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, RewardsState>((ref) {
  return RewardsNotifier();
});

class RewardsNotifier extends StateNotifier<RewardsState> {
  RewardsNotifier() : super(RewardsState());

  void awardFirstAchievement() {
    // Logic to award first achievement
    // Update user progress, add points, etc.
  }
}

class RewardsState {
  final int points;
  final List<String> achievements;

  RewardsState({this.points = 0, this.achievements = const []});
}