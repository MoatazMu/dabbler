import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class GameShareService {
  static Future<void> shareGame({
    required String title,
    required DateTime dateTime,
    required String venue,
    required String url,
  }) async {
    final date = '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    final text = 'Join me for "$title" on $date at $venue. More details: $url';
    await Share.share(text, subject: title);
  }

  static Future<void> shareViaWhatsApp(String text) async {
    await Share.share(text); // Share sheet includes WhatsApp if installed
  }
}

class GameShareCard extends StatelessWidget {
  final String title;
  final String sport;
  final DateTime dateTime;
  final String venue;
  final double price;
  const GameShareCard({super.key, required this.title, required this.sport, required this.dateTime, required this.venue, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$sport • $venue', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(_format(dateTime), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(price == 0 ? 'Free' : '24${price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.green[700])),
        ],
      ),
    );
  }

  String _format(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day}/${d.month}/${d.year} at $hour:$minute $ampm';
  }
}
