class BuildRequestModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String requestType; // website, mobile_app, both
  final String status;
  final String complexity;
  final String hostingType; // vercel, replit, heroku, whitelabel
  final String? whitelabelDomain;
  final String? whitelabelBranding;
  final String? whitelabelHostingPlatform;
  final String? techRequirements;
  final String? referenceLinks;
  final String? figmaLink;
  final String? hostingEmail;
  final double estimatedCost;
  final bool isFree;
  final String? deliveryUrl;
  final String? repoUrl;
  final DateTime? scheduledWeekend;
  final DateTime createdAt;
  final DateTime? completedAt;

  BuildRequestModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.requestType,
    required this.status,
    required this.complexity,
    required this.hostingType,
    this.whitelabelDomain,
    this.whitelabelBranding,
    this.whitelabelHostingPlatform,
    this.techRequirements,
    this.referenceLinks,
    this.figmaLink,
    this.hostingEmail,
    required this.estimatedCost,
    required this.isFree,
    this.deliveryUrl,
    this.repoUrl,
    this.scheduledWeekend,
    required this.createdAt,
    this.completedAt,
  });

  factory BuildRequestModel.fromJson(Map<String, dynamic> json) {
    return BuildRequestModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requestType: json['request_type'] ?? 'website',
      status: json['status'] ?? 'pending',
      complexity: json['complexity'] ?? 'basic',
      hostingType: json['hosting_type'] ?? 'vercel',
      whitelabelDomain: json['whitelabel_domain'],
      whitelabelBranding: json['whitelabel_branding'],
      whitelabelHostingPlatform: json['whitelabel_hosting_platform'],
      techRequirements: json['tech_requirements'],
      referenceLinks: json['reference_links'],
      figmaLink: json['figma_link'],
      hostingEmail: json['hosting_email'],
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
      isFree: json['is_free'] ?? true,
      deliveryUrl: json['delivery_url'],
      repoUrl: json['repo_url'],
      scheduledWeekend: json['scheduled_weekend'] != null
          ? DateTime.tryParse(json['scheduled_weekend'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '⏳ Pending Review';
      case 'queued':
        return '📋 Queued';
      case 'scheduled':
        return '📅 Scheduled';
      case 'building':
        return '🔨 Building';
      case 'review':
        return '👀 In Review';
      case 'deploying':
        return '🚀 Deploying';
      case 'completed':
        return '✅ Completed';
      case 'cancelled':
        return '❌ Cancelled';
      case 'rejected':
        return '🚫 Rejected';
      default:
        return status;
    }
  }

  String get typeLabel {
    switch (requestType) {
      case 'website':
        return '🌐 Website';
      case 'mobile_app':
        return '📱 Mobile App';
      case 'both':
        return '🌐📱 Website + App';
      default:
        return requestType;
    }
  }

  String get costLabel {
    if (isFree) return 'FREE';
    return '₹${estimatedCost.toStringAsFixed(0)}';
  }
}

class CreateBuildRequestInput {
  final String title;
  final String description;
  final String requestType;
  final String hostingType;
  final String? techRequirements;
  final String? referenceLinks;
  final String? figmaLink;
  final String? hostingEmail;
  final String? whitelabelDomain;
  final String? whitelabelBranding;
  final String? whitelabelHostingPlatform;

  CreateBuildRequestInput({
    required this.title,
    required this.description,
    required this.requestType,
    required this.hostingType,
    this.techRequirements,
    this.referenceLinks,
    this.figmaLink,
    this.hostingEmail,
    this.whitelabelDomain,
    this.whitelabelBranding,
    this.whitelabelHostingPlatform,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'request_type': requestType,
      'hosting_type': hostingType,
      if (techRequirements != null) 'tech_requirements': techRequirements,
      if (referenceLinks != null) 'reference_links': referenceLinks,
      if (figmaLink != null) 'figma_link': figmaLink,
      if (hostingEmail != null) 'hosting_email': hostingEmail,
      if (whitelabelDomain != null) 'whitelabel_domain': whitelabelDomain,
      if (whitelabelBranding != null) 'whitelabel_branding': whitelabelBranding,
      if (whitelabelHostingPlatform != null)
        'whitelabel_hosting_platform': whitelabelHostingPlatform,
    };
  }
}
