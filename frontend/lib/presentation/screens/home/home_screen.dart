import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Make It Exist'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogout());
                  context.go('/login');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFF8B83FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey ${user?.fullName?.split(' ').first ?? 'there'}! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What would you like us to build this weekend?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/new-request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                        ),
                        child: const Text('Submit New Request'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_circle_outline,
                        label: 'New\nRequest',
                        color: AppTheme.primaryColor,
                        onTap: () => context.go('/new-request'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.list_alt,
                        label: 'My\nRequests',
                        color: AppTheme.secondaryColor,
                        onTap: () => context.go('/my-requests'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.calendar_today,
                        label: 'Build\nSchedule',
                        color: AppTheme.warningColor,
                        onTap: () => context.go('/schedule'),
                      ),
                    ),
                  ],
                ),
                if (user != null && user.isAdmin) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _ActionCard(
                      icon: Icons.admin_panel_settings,
                      label: '🔑 Manage Users & Reset Passwords',
                      color: Colors.red,
                      onTap: () => context.go('/admin/users'),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Pricing Info
                const Text(
                  'What We Build',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _PricingCard(
                  title: '🌐 Website',
                  subtitle: 'Landing pages, portfolios, business sites',
                  price: 'FREE',
                  priceColor: AppTheme.freeColor,
                  features: const [
                    'Built over the weekend (8hrs/day)',
                    'Free hosting on Vercel/Replit/Heroku',
                    'Your email-linked account',
                  ],
                ),
                const SizedBox(height: 12),
                _PricingCard(
                  title: '📱 Mobile App',
                  subtitle: 'Android & iOS apps',
                  price: 'Talk to Builder',
                  priceColor: AppTheme.accentColor,
                  features: const [
                    'Cross-platform Flutter apps',
                    'Pricing discussed with your builder',
                    'Built & delivered in weekends',
                  ],
                ),
                const SizedBox(height: 12),
                _PricingCard(
                  title: '🏷️ Whitelabel',
                  subtitle: 'Your brand, your domain, your hosting',
                  price: 'Talk to Builder',
                  priceColor: AppTheme.accentColor,
                  features: const [
                    'Custom domain & branding',
                    'Deploy to your choice of hosting',
                    'Pricing discussed with your builder',
                  ],
                ),
                const SizedBox(height: 32),

                // How it works
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ How It Works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StepItem(number: '1', text: 'Submit your build request'),
                      _StepItem(number: '2', text: 'A builder reviews & contacts you'),
                      _StepItem(number: '3', text: 'Request gets queued for the weekend'),
                      _StepItem(number: '4', text: 'We build it (Sat + Sun, 8hrs/day)'),
                      _StepItem(number: '5', text: 'Get your live URL & repo! 🎉'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final Color priceColor;
  final List<String> features;

  const _PricingCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceColor,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: priceColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: priceColor),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
