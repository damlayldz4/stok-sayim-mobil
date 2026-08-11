enum StockCountStatus { draft, inProgress, completed, cancelled }

StockCountStatus stockCountStatusFromString(String value) {
  switch (value) {
    case 'draft':
      return StockCountStatus.draft;
    case 'in_progress':
      return StockCountStatus.inProgress;
    case 'completed':
      return StockCountStatus.completed;
    case 'cancelled':
      return StockCountStatus.cancelled;
    default:
      throw ArgumentError('Bilinmeyen sayım durumu: $value');
  }
}

extension StockCountStatusLabel on StockCountStatus {
  String get label {
    switch (this) {
      case StockCountStatus.draft:
        return 'Taslak';
      case StockCountStatus.inProgress:
        return 'Devam Ediyor';
      case StockCountStatus.completed:
        return 'Tamamlandı';
      case StockCountStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}

class StockCount {
  final int id;
  final String name;
  final String branchName;
  final String warehouseName;
  final StockCountStatus status;
  final String startDate;
  final String endDate;
  final String? description;
  final List<String> shelfCodes;
  final List<String> assignedUserNames;

  StockCount({
    required this.id,
    required this.name,
    required this.branchName,
    required this.warehouseName,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.description,
    this.shelfCodes = const [],
    this.assignedUserNames = const [],
  });

  /// API'nin index() çağrısı sadece branch/warehouse ile döner (shelves,
  /// assigned_users olmayabilir); show() çağrısı hepsini döner. Bu yüzden
  /// bu alanları opsiyonel/varsayılan boş liste olarak çözüyoruz.
  factory StockCount.fromJson(Map<String, dynamic> json) {
    final shelves = (json['shelves'] as List<dynamic>?) ?? [];
    final assignedUsers = (json['assigned_users'] as List<dynamic>?) ?? [];

    return StockCount(
      id: json['id'] as int,
      name: json['name'] as String,
      branchName: (json['branch']?['name'] as String?) ?? '',
      warehouseName: (json['warehouse']?['name'] as String?) ?? '',
      status: stockCountStatusFromString(json['status'] as String),
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      description: json['description'] as String?,
      shelfCodes: shelves.map((s) => s['shelf_code'] as String).toList(),
      assignedUserNames: assignedUsers.map((u) => u['name'] as String).toList(),
    );
  }
}
