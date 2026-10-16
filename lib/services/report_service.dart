import '../core/supabase.dart';
import '../models/report.dart';

class ReportService {
  Future<void> create({
    required String listingId,
    required String listingTitle,
    required String reporterId,
    required String reporterName,
    required String reason,
    String? description,
  }) async {
    final report = Report(
      id: '',
      listingId: listingId,
      listingTitle: listingTitle,
      reporterId: reporterId,
      reporterName: reporterName,
      reason: reason,
      description: description,
    );
    await supabase.from('reports').insert(report.toMap());
  }

  Future<List<Report>> recent({int limit = 100}) async {
    final rows = await supabase
        .from('reports')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => Report.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> delete(String id) async {
    await supabase.from('reports').delete().eq('id', id);
  }
}
