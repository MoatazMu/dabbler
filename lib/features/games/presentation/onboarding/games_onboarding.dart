import 'package:flutter/material.dart';

class GamesOnboarding extends StatefulWidget {
  final VoidCallback? onFinished;
  const GamesOnboarding({super.key, this.onFinished});

  @override
  State<GamesOnboarding> createState() => _GamesOnboardingState();
}

class _GamesOnboardingState extends State<GamesOnboarding> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPage(
      title: 'Discover Games',
      subtitle: 'Find nearby games that match your skill level and schedule',
      icon: Icons.sports_soccer,
    ),
    _OnboardPage(
      title: 'Create a Game',
      subtitle: 'Set up your own game and invite friends easily',
      icon: Icons.add_circle_outline,
    ),
    _OnboardPage(
      title: 'Join & Check-in',
      subtitle: 'Join games and check in quickly at the venue',
      icon: Icons.verified_user_outlined,
    ),
    _OnboardPage(
      title: 'Skill Levels',
      subtitle: 'Beginner, Intermediate, Advanced — pick what suits you',
      icon: Icons.star_half,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  ),
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final selected = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 10 : 6,
                        height: selected ? 10 : 6,
                        decoration: BoxDecoration(
                          color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_index == _pages.length - 1 ? 'Start' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _skip() {
    widget.onFinished?.call();
    Navigator.of(context).maybePop();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _skip();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardPage({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
