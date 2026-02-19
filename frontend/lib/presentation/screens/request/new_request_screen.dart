import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/request_model.dart';
import '../../blocs/request/request_bloc.dart';
import '../../blocs/request/request_event.dart';
import '../../blocs/request/request_state.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _techController = TextEditingController();
  final _referenceController = TextEditingController();
  final _figmaController = TextEditingController();
  final _hostingEmailController = TextEditingController();
  final _whitelabelDomainController = TextEditingController();
  final _whitelabelBrandingController = TextEditingController();

  String _requestType = 'website';
  String _hostingType = 'vercel';
  String _whitelabelHosting = '';

  bool get _isFree => _requestType == 'website' && _hostingType != 'whitelabel';
  bool get _isWhitelabel => _hostingType == 'whitelabel';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _techController.dispose();
    _referenceController.dispose();
    _figmaController.dispose();
    _hostingEmailController.dispose();
    _whitelabelDomainController.dispose();
    _whitelabelBrandingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RequestBloc, RequestState>(
      listener: (context, state) {
        if (state is RequestCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Request submitted! You\'ll be contacted by a builder.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.go('/my-requests');
        } else if (state is RequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Build Request'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text('📋', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submit your build request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'A building engineer will review & discuss pricing with you directly',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Request Type
                const Text('What do you need? *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTypeSelector(),
                const SizedBox(height: 20),

                // Title
                TextFormField(
                  controller: _titleController,
                  validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Project Title *',
                    hintText: 'e.g., Portfolio Website for Photography',
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (v) => v?.isEmpty == true ? 'Description is required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe what you want built, features, pages, etc.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Tech Requirements
                TextFormField(
                  controller: _techController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Tech Requirements (Optional)',
                    hintText: 'e.g., React, Auth, Maps API, Notifications...',
                  ),
                ),
                const SizedBox(height: 16),

                // Reference Links
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Links (Optional)',
                    hintText: 'Links to similar sites/apps for inspiration',
                  ),
                ),
                const SizedBox(height: 16),

                // Figma
                TextFormField(
                  controller: _figmaController,
                  decoration: const InputDecoration(
                    labelText: 'Figma / Design Link (Optional)',
                    hintText: 'https://figma.com/...',
                  ),
                ),
                const SizedBox(height: 24),

                // Hosting Type
                const Text('Hosting Preference *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildHostingSelector(),
                const SizedBox(height: 16),

                // Hosting Email
                if (!_isWhitelabel) ...[
                  TextFormField(
                    controller: _hostingEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Your Hosting Account Email',
                      hintText: 'Email linked to your Vercel/Replit/Heroku account',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Whitelabel fields
                if (_isWhitelabel) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🏷️ Whitelabel Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _whitelabelDomainController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Domain',
                            hintText: 'e.g., www.yourbrand.com',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _whitelabelBrandingController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Branding Details',
                            hintText: 'Colors, logo URL, brand guidelines...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _whitelabelHosting.isEmpty ? null : _whitelabelHosting,
                          decoration: const InputDecoration(
                            labelText: 'Hosting Platform',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'aws', child: Text('AWS')),
                            DropdownMenuItem(value: 'gcp', child: Text('Google Cloud')),
                            DropdownMenuItem(value: 'azure', child: Text('Azure')),
                            DropdownMenuItem(value: 'digitalocean', child: Text('DigitalOcean')),
                            DropdownMenuItem(value: 'netlify', child: Text('Netlify')),
                            DropdownMenuItem(value: 'custom', child: Text('Other / Custom')),
                          ],
                          onChanged: (v) => setState(() => _whitelabelHosting = v ?? ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Submit Button
                BlocBuilder<RequestBloc, RequestState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state is RequestSubmitting
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<RequestBloc>().add(
                                        CreateRequest(
                                          input: CreateBuildRequestInput(
                                            title: _titleController.text.trim(),
                                            description: _descriptionController.text.trim(),
                                            requestType: _requestType,
                                            hostingType: _hostingType,
                                            techRequirements: _techController.text.trim().isEmpty
                                                ? null
                                                : _techController.text.trim(),
                                            referenceLinks: _referenceController.text.trim().isEmpty
                                                ? null
                                                : _referenceController.text.trim(),
                                            figmaLink: _figmaController.text.trim().isEmpty
                                                ? null
                                                : _figmaController.text.trim(),
                                            hostingEmail: _hostingEmailController.text.trim().isEmpty
                                                ? null
                                                : _hostingEmailController.text.trim(),
                                            whitelabelDomain: _whitelabelDomainController.text.trim().isEmpty
                                                ? null
                                                : _whitelabelDomainController.text.trim(),
                                            whitelabelBranding: _whitelabelBrandingController.text.trim().isEmpty
                                                ? null
                                                : _whitelabelBrandingController.text.trim(),
                                            whitelabelHostingPlatform: _whitelabelHosting.isEmpty
                                                ? null
                                                : _whitelabelHosting,
                                          ),
                                        ),
                                      );
                                }
                              },
                        child: state is RequestSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Submit Request 🚀'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _TypeChip(
          label: '🌐 Website',
          isSelected: _requestType == 'website',
          onTap: () => setState(() => _requestType = 'website'),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: '📱 Mobile App',
          isSelected: _requestType == 'mobile_app',
          onTap: () => setState(() => _requestType = 'mobile_app'),
        ),
        const SizedBox(width: 8),
        _TypeChip(
          label: '🌐📱 Both',
          isSelected: _requestType == 'both',
          onTap: () => setState(() => _requestType = 'both'),
        ),
      ],
    );
  }

  Widget _buildHostingSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TypeChip(
          label: '▲ Vercel',
          isSelected: _hostingType == 'vercel',
          onTap: () => setState(() => _hostingType = 'vercel'),
        ),
        _TypeChip(
          label: '⚡ Replit',
          isSelected: _hostingType == 'replit',
          onTap: () => setState(() => _hostingType = 'replit'),
        ),
        _TypeChip(
          label: '🟣 Heroku',
          isSelected: _hostingType == 'heroku',
          onTap: () => setState(() => _hostingType = 'heroku'),
        ),
        _TypeChip(
          label: '🏷️ Whitelabel',
          isSelected: _hostingType == 'whitelabel',
          onTap: () => setState(() => _hostingType = 'whitelabel'),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
