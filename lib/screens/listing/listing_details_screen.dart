import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/ext.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../utils/formatters.dart';
import '../../utils/labels.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/state_views.dart';
import '../../services/report_service.dart';

class ListingDetailsScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailsScreen({super.key, required this.listingId});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final _listingService = ListingService();
  final _userService = UserService();
  final _reportService = ReportService();

  Listing? _listing;
  List<String> _images = [];
  int _imageIndex = 0;
  bool _loading = true;
  String? _error;
  bool _showContact = false;
  bool _acting = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _isOwner => _uid == _listing?.ownerId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final listing = await _listingService.byId(widget.listingId);
      if (listing == null) {
        if (mounted && !quiet) {
          setState(() {
            _error = context.l10n.listingNotFound;
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
      if (mounted && !quiet) {
        setState(() {
          _error = dataErrorMessage(context, e);
          _loading = false;
        });
      }
    }
  }

  void _snack(String Function(BuildContext) message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message(context))));
  }

  /// Reserve the listing. On a rules denial, probe the document: if it is
  /// no longer available another user won the race ("claim taken"),
  /// otherwise surface the normal error message.
  Future<void> _claim() async {
    final uid = _uid;
    if (uid == null || _acting || _listing == null) return;
    setState(() => _acting = true);
    try {
      final user = await _userService.getById(uid);
      await _listingService.claim(
        widget.listingId,
        uid: uid,
        name: user?.fullName ?? 'مستخدم',
      );
      await _load(quiet: true);
      _snack((c) => c.l10n.claimSuccess);
    } catch (e) {
      Listing? fresh;
      try {
        fresh = await _listingService.byId(widget.listingId);
      } catch (_) {}
      if (fresh != null && !fresh.isAvailable) {
        await _load(quiet: true);
        _snack((c) => c.l10n.claimTaken);
      } else {
        await _load(quiet: true);
        _snack((c) => dataErrorMessage(c, e));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancelClaim() async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await _listingService.cancelClaim(widget.listingId);
      await _load(quiet: true);
      _snack((c) => c.l10n.claimCancelled);
    } catch (e) {
      await _load(quiet: true);
      _snack((c) => dataErrorMessage(c, e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmDelivery() async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await _listingService.confirmDelivery(widget.listingId);
      await _load(quiet: true);
      _snack((c) => c.l10n.deliveryConfirmed);
    } catch (e) {
      await _load(quiet: true);
      _snack((c) => dataErrorMessage(c, e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  /// Reservation action area — differs by role and status:
  /// * visitor + available  -> claim button
  /// * visitor + reserved by me -> cancel button
  /// * owner + reserved     -> confirm delivery + release
  /// * visitor + reserved by other -> info card only
  Widget _buildClaimArea(
      Listing listing, ThemeData theme, AppLocalizations l) {
    if (listing.isAvailable && !_isOwner) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _acting ? null : _claim,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(l.claimRequest),
        ),
      );
    }
    if (!listing.isReserved) return const SizedBox.shrink();

    final mine = _uid != null && listing.claimedBy == _uid;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_added_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.reservedBy(listing.claimedByName ?? '—'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (_isOwner) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _acting ? null : _confirmDelivery,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l.confirmDelivery),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _acting ? null : _cancelClaim,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(l.claimRelease),
              ),
            ] else if (mine) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _acting ? null : _cancelClaim,
                icon: const Icon(Icons.bookmark_remove_outlined),
                label: Text(l.claimCancel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _report() async {
    final l = context.l10n;
    String reason = kReportReasons.first;
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.reportTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: reason,
                isExpanded: true,
                items: kReportReasons
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(reportReasonLabel(ctx, r)),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => reason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                decoration: InputDecoration(
                  labelText: l.reportDescLabel,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.reportSubmit),
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
          SnackBar(content: Text(context.l10n.reportSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dataErrorMessage(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: LoadingView(message: context.l10n.loading),
      );
    }
    if (_error != null || _listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _error ?? context.l10n.errGeneric, onRetry: _load),
      );
    }
    final listing = _listing!;
    final theme = Theme.of(context);
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.detailsTitle),
        actions: [
          if (!_isOwner)
            IconButton(
              tooltip: l.report,
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
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _imageIndex ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
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
                height: 220,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: listing.isAvailable
                              ? theme.colorScheme.primaryContainer
                              : listing.isReserved
                                  ? theme.colorScheme.secondaryContainer
                                  : theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel(context, listing.status),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: listing.isAvailable
                                ? theme.colorScheme.onPrimaryContainer
                                : listing.isReserved
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoChip(
                        icon: Icons.category_outlined,
                        label: categoryLabel(context, listing.category),
                      ),
                      InfoChip(
                        icon: Icons.star_outline,
                        label: conditionLabel(context, listing.condition),
                      ),
                      InfoChip(
                        icon: Icons.place_outlined,
                        label: '${listing.wilaya} - ${listing.commune}',
                      ),
                      InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: formatDate(listing.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(l.description, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.ownerName,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  l.ownerLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildClaimArea(listing, theme, l),
                  if (listing.contactPhone != null &&
                      listing.contactPhone!.isNotEmpty) ...[
                    if (_showContact)
                      Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color:
                                    theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                listing.contactPhone!,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color:
                                      theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => setState(() => _showContact = true),
                          icon: const Icon(Icons.contact_phone_outlined),
                          label: Text(l.showPhone),
                        ),
                      ),
                  ] else if (!_isOwner)
                    Text(
                      l.noPhone,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
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
