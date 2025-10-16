import 'package:flutter/material.dart';

enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  stormy,
  snowy,
  windy,
  foggy,
  hot,
  cold,
}

class WeatherIndicator extends StatefulWidget {
  final WeatherCondition condition;
  final double temperature; // in Celsius
  final String? location;
  final bool showForecast;
  final bool showAlerts;
  final bool isExpandable;
  final List<Map<String, dynamic>>? forecast; // For expandable forecast
  final List<String>? alerts; // Weather alerts
  final VoidCallback? onTap;

  const WeatherIndicator({
    super.key,
    required this.condition,
    required this.temperature,
    this.location,
    this.showForecast = false,
    this.showAlerts = true,
    this.isExpandable = false,
    this.forecast,
    this.alerts,
    this.onTap,
  });

  @override
  State<WeatherIndicator> createState() => _WeatherIndicatorState();
}

class _WeatherIndicatorState extends State<WeatherIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainWeatherCard(),
        if (_isExpanded && widget.isExpandable) ...[
          const SizedBox(height: 8),
          _buildExpandedForecast(),
        ],
        if (widget.alerts != null && widget.alerts!.isNotEmpty && widget.showAlerts)
          ...[
            const SizedBox(height: 8),
            _buildWeatherAlerts(),
          ],
      ],
    );
  }

  Widget _buildMainWeatherCard() {
    final weatherData = _getWeatherData();
    
    return GestureDetector(
      onTap: () {
        if (widget.isExpandable) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        }
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isExpanded ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: weatherData.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: weatherData.gradientColors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWeatherIcon(weatherData),
                  const SizedBox(width: 12),
                  _buildWeatherInfo(weatherData),
                  if (widget.isExpandable) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherIcon(WeatherData weatherData) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              weatherData.icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherInfo(WeatherData weatherData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '${widget.temperature.round()}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_fahrenheitFromCelsius(widget.temperature).round()}°F',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          weatherData.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.location != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.location!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedForecast() {
    if (widget.forecast == null || widget.forecast!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '7-day forecast not available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Forecast',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.forecast!.take(7).map((day) => _buildForecastDay(day)),
        ],
      ),
    );
  }

  Widget _buildForecastDay(Map<String, dynamic> day) {
    final condition = day['condition'] as WeatherCondition;
    final weatherData = _getWeatherDataForCondition(condition);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day['day'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            weatherData.icon,
            size: 20,
            color: weatherData.gradientColors.first,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              weatherData.description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${(day['high'] as double).round()}°/${(day['low'] as double).round()}°',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlerts() {
    return Column(
      children: widget.alerts!.map((alert) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  WeatherData _getWeatherData() {
    return _getWeatherDataForCondition(widget.condition);
  }

  WeatherData _getWeatherDataForCondition(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return WeatherData(
          icon: Icons.wb_sunny,
          description: 'Sunny',
          gradientColors: [Colors.orange[400]!, Colors.yellow[300]!],
        );
      case WeatherCondition.partlyCloudy:
        return WeatherData(
          icon: Icons.wb_cloudy,
          description: 'Partly Cloudy',
          gradientColors: [Colors.blue[300]!, Colors.lightBlue[200]!],
        );
      case WeatherCondition.cloudy:
        return WeatherData(
          icon: Icons.cloud,
          description: 'Cloudy',
          gradientColors: [Colors.grey[400]!, Colors.grey[300]!],
        );
      case WeatherCondition.rainy:
        return WeatherData(
          icon: Icons.beach_access,
          description: 'Rainy',
          gradientColors: [Colors.blue[600]!, Colors.blue[400]!],
        );
      case WeatherCondition.stormy:
        return WeatherData(
          icon: Icons.flash_on,
          description: 'Stormy',
          gradientColors: [Colors.purple[700]!, Colors.indigo[500]!],
        );
      case WeatherCondition.snowy:
        return WeatherData(
          icon: Icons.ac_unit,
          description: 'Snowy',
          gradientColors: [Colors.cyan[200]!, Colors.blue[100]!],
        );
      case WeatherCondition.windy:
        return WeatherData(
          icon: Icons.air,
          description: 'Windy',
          gradientColors: [Colors.teal[300]!, Colors.cyan[200]!],
        );
      case WeatherCondition.foggy:
        return WeatherData(
          icon: Icons.cloud,
          description: 'Foggy',
          gradientColors: [Colors.grey[300]!, Colors.grey[200]!],
        );
      case WeatherCondition.hot:
        return WeatherData(
          icon: Icons.wb_sunny,
          description: 'Hot',
          gradientColors: [Colors.red[400]!, Colors.orange[400]!],
        );
      case WeatherCondition.cold:
        return WeatherData(
          icon: Icons.ac_unit,
          description: 'Cold',
          gradientColors: [Colors.blue[400]!, Colors.lightBlue[300]!],
        );
    }
  }

  double _fahrenheitFromCelsius(double celsius) {
    return (celsius * 9 / 5) + 32;
  }
}

class WeatherData {
  final IconData icon;
  final String description;
  final List<Color> gradientColors;

  WeatherData({
    required this.icon,
    required this.description,
    required this.gradientColors,
  });
}

// Utility function to get weather alerts based on condition and temperature
List<String> getWeatherAlerts(WeatherCondition condition, double temperature) {
  final alerts = <String>[];

  switch (condition) {
    case WeatherCondition.rainy:
    case WeatherCondition.stormy:
      alerts.add('Bring rain gear - outdoor game may be affected');
      break;
    case WeatherCondition.snowy:
      alerts.add('Snow conditions - check if venue is accessible');
      break;
    case WeatherCondition.windy:
      alerts.add('Windy conditions may affect ball sports');
      break;
    default:
      break;
  }

  if (temperature > 35) {
    alerts.add('Very hot - bring extra water and sun protection');
  } else if (temperature < 5) {
    alerts.add('Very cold - dress warmly');
  } else if (temperature > 30) {
    alerts.add('Hot weather - stay hydrated');
  }

  return alerts;
}
