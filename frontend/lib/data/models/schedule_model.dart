class ScheduleModel {
  final String id;
  final DateTime date;
  final String dayOfWeek;
  final int totalHours;
  final int bookedHours;
  final int maxProjects;
  final int bookedProjects;
  final String status;

  ScheduleModel({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    required this.totalHours,
    required this.bookedHours,
    required this.maxProjects,
    required this.bookedProjects,
    required this.status,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      dayOfWeek: json['day_of_week'] ?? '',
      totalHours: json['total_hours'] ?? 8,
      bookedHours: json['booked_hours'] ?? 0,
      maxProjects: json['max_projects'] ?? 5,
      bookedProjects: json['booked_projects'] ?? 0,
      status: json['status'] ?? 'available',
    );
  }

  int get availableHours => totalHours - bookedHours;
  int get availableProjects => maxProjects - bookedProjects;
  bool get isFull => status == 'full';
  double get utilization => bookedHours / totalHours;

  String get statusLabel {
    switch (status) {
      case 'available': return '🟢 Available';
      case 'booked': return '🟡 Partially Booked';
      case 'full': return '🔴 Full';
      default: return status;
    }
  }
}
