import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../services/report_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/state_views.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailsScreen({super.key, required this.listingId});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final _listingService = ListingService();
  final _reportService = ReportService();
  final _userService = UserService();

  Listing? _listing;
  List<String> _images = [];
  bool _loading = true;
  String? _error;
  bool _showContact = false;
  int _imageIndex = 0;

  bool get _isOwner =>
      _listing != null &&
      _listing!.ownerId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await _listingService.byId(widget.listingId);
      if (listing == null) {
        if (mounted) {
          setState(() {
            _error = 'لم يتم العثور على الإعلان';
            _loading = false;
          });
        }
        return;
      }
      List<String> images = const [];
      if (listing.imageCount > 0) {
        images = await _listingService.imagesOf(widget.listingId);
      }
      if (mounted) {
        setState(() {
          _listing = listing;
          _images = images;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dataErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _report() async {
    String reason = kReportReasons.first;
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('الإبلاغ عن الإعلان'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: reason,
                isExpanded: true,
                items: kReportReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setDialogState(() => reason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف إضافي (اختياري)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final user = await _userService.getById(uid);
      await _reportService.create(
        listingId: widget.listingId,
        listingTitle: _listing!.title,
        reporterId: uid,
        reporterName: user?.fullName ?? 'مستخدم',
        reason: reason,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال البلاغ، شكراً لتعاونك')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView(message: 'جاري التحميل...'));
    }
    if (_error != null || _listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'خطأ', onRetry: _load),
      );
    }
    final listing = _listing!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإعلان'),
        actions: [
          if (!_isOwner)
            IconButton(
              tooltip: 'الإبلاغ',
              icon: const Icon(Icons.flag_outlined),
              onPressed: _report,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: _images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (context, i) =>
                      Base64Image(data: _images[i]),
                ),
              ),
              if (_images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _images.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _imageIndex
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ] else
              Container(
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(
                    child: Icon(Icons.image_outlined, size: 64)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: listing.isAvailable
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(listing.status,
                            style: theme.textTheme.labelMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.category_outlined, label: listing.category),
                      _InfoChip(icon: Icons.star_outline, label: listing.condition),
                      _InfoChip(
                        icon: Icons.place_outlined,
                        label: '${listing.wilaya} - ${listing.commune}',
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: formatDate(listing.createdAt),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('الوصف', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(listing.description,
                      style: theme.textTheme.bodyLarge),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person_outlined),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listing.ownerName,
                              style: theme.textTheme.titleSmall),
                          Text('صاحب الإعلان',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (listing.contactPhone != null &&
                      listing.contactPhone!.isNotEmpty) ...[
                    if (_showContact)
                      Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_outlined),
                              const SizedBox(width: 12),
                              Text(
                                listing.contactPhone!,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              setState(() => _showContact = true),
                          icon: const Icon(Icons.contact_phone_outlined),
                          label: const Text('إظهار رقم التواصل'),
                        ),
                      ),
                  ] else if (!_isOwner)
                    Text(
                      'صاحب الإعلان لم يترك رقم هاتف',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
