import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate next weekend dates
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday + 7) % 7;
    final nextSaturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    final nextSunday = nextSaturday.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.secondaryColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text('📅', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekend Build Schedule',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'We build every Saturday & Sunday, 8 hours per day',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Upcoming Weekends',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Next 4 weekends
            for (int i = 0; i < 4; i++) ...[
              _WeekendCard(
                saturday: nextSaturday.add(Duration(days: i * 7)),
                sunday: nextSunday.add(Duration(days: i * 7)),
                isNext: i == 0,
                slotsAvailable: 5 - i, // Mock data
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 24),

            // Build process info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔧 Build Process',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _InfoRow(icon: '⏰', text: '8 hours per day (10 AM - 6 PM)'),
                  _InfoRow(icon: '📋', text: 'Max 5 projects per weekend'),
                  _InfoRow(icon: '🏗️', text: 'Just-in-time build approach'),
                  _InfoRow(icon: '🚀', text: 'Deployed by Sunday evening'),
                  _InfoRow(icon: '🔗', text: 'Repo + Live URL delivered'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _WeekendCard extends StatelessWidget {
  final DateTime saturday;
  final DateTime sunday;
  final bool isNext;
  final int slotsAvailable;

  const _WeekendCard({
    required this.saturday,
    required this.sunday,
    required this.isNext,
    required this.slotsAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNext ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey[200]!,
          width: isNext ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isNext ? AppTheme.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '${saturday.day}-${sunday.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isNext ? Colors.white : Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                Text(
                  months[saturday.month - 1],
                  style: TextStyle(
                    color: isNext ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sat & Sun',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isNext ? AppTheme.primaryColor : null,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '16 hours total • $slotsAvailable slots available',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(
            slotsAvailable > 0 ? Icons.check_circle : Icons.cancel,
            color: slotsAvailable > 0 ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
