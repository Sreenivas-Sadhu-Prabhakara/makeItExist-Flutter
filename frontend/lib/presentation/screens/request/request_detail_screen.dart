import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/request/request_bloc.dart';
import '../../blocs/request/request_event.dart';
import '../../blocs/request/request_state.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RequestBloc>().add(LoadRequestDetail(id: widget.requestId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/my-requests'),
        ),
      ),
      body: BlocBuilder<RequestBloc, RequestState>(
        builder: (context, state) {
          if (state is RequestLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RequestError) {
            return Center(child: Text(state.message));
          }

          if (state is RequestDetailLoaded) {
            final req = state.request;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(req.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.statusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _statusColor(req.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(req.typeLabel),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: req.isFree
                              ? AppTheme.freeColor.withOpacity(0.1)
                              : AppTheme.paidColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.costLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: req.isFree ? AppTheme.freeColor : AppTheme.paidColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    req.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted ${DateFormat.yMMMMd().format(req.createdAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _DetailSection(title: 'Description', content: req.description),

                  if (req.techRequirements != null && req.techRequirements!.isNotEmpty)
                    _DetailSection(title: 'Tech Requirements', content: req.techRequirements!),

                  if (req.referenceLinks != null && req.referenceLinks!.isNotEmpty)
                    _DetailSection(title: 'Reference Links', content: req.referenceLinks!),

                  if (req.figmaLink != null && req.figmaLink!.isNotEmpty)
                    _DetailSection(title: 'Figma Link', content: req.figmaLink!),

                  // Hosting
                  _DetailSection(
                    title: 'Hosting',
                    content: req.hostingType == 'whitelabel'
                        ? 'Whitelabel: ${req.whitelabelDomain ?? 'TBD'}'
                        : '${req.hostingType.toUpperCase()} (${req.hostingEmail ?? 'Not provided'})',
                  ),

                  // Delivery
                  if (req.deliveryUrl != null && req.deliveryUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎉 Your build is live!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text('URL: ${req.deliveryUrl}'),
                          if (req.repoUrl != null) Text('Repo: ${req.repoUrl}'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppTheme.successColor;
      case 'building': return AppTheme.primaryColor;
      case 'cancelled':
      case 'rejected': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;

  const _DetailSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
