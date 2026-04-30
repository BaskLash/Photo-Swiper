import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/purchase_service.dart';

/// Premium subscription paywall. Returns `true` from [Navigator.pop] when the
/// user successfully purchases or restores a pro entitlement.
class PaywallScreen extends StatefulWidget {
  /// When true, the user has hit the free-tier limit and may only leave the
  /// paywall by purchasing or explicitly cancelling. The close button is still
  /// shown but tapping it pops with `false`, which the caller uses to decide
  /// whether to keep the swipe screen blocked.
  final bool blocking;

  const PaywallScreen({super.key, this.blocking = true});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _service = PurchaseService.instance;

  Offering? _offering;
  Package? _selected;
  bool _loadingOfferings = true;
  bool _purchasing = false;
  String? _errorMessage;

  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF1C1C1E);
  static const Color _accent = Color(0xFF6B4EFF);
  static const Color _accentSoft = Color(0xFF8B7BFF);
  static const Color _muted = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final cached = _service.currentOffering;
    if (cached != null && cached.availablePackages.isNotEmpty) {
      setState(() {
        _offering = cached;
        _selected = _defaultSelection(cached);
        _loadingOfferings = false;
      });
      return;
    }
    final fetched = await _service.fetchOfferings();
    if (!mounted) return;
    setState(() {
      _offering = fetched;
      _selected = (fetched != null && fetched.availablePackages.isNotEmpty)
          ? _defaultSelection(fetched)
          : null;
      _loadingOfferings = false;
      if (fetched == null || fetched.availablePackages.isEmpty) {
        _errorMessage = _describeOfferingProblem();
      }
    });
  }

  /// Translates the SDK state into a developer-friendly message so we can
  /// see the actual cause when offerings fail to load.
  String _describeOfferingProblem() {
    final err = _service.lastError;
    if (err != null) {
      return 'RevenueCat error: $err';
    }
    if (_service.hasNoCurrentOffering) {
      return 'No "current" offering set in RevenueCat. Open your '
          'RevenueCat dashboard → Offerings, mark one offering as Current, '
          'and attach your weekly/monthly/yearly products to it.';
    }
    if (_service.hasOfferingButNoPackages) {
      return 'Your current offering has no packages. Add weekly/monthly/'
          'yearly packages in RevenueCat and link them to App Store Connect '
          'products.';
    }
    return 'Could not load subscription options. Please try again.';
  }

  /// Default selection prioritises annual (highest LTV / strongest anchor).
  Package? _defaultSelection(Offering offering) {
    return offering.annual ?? offering.monthly ?? offering.weekly ??
        (offering.availablePackages.isNotEmpty
            ? offering.availablePackages.first
            : null);
  }

  Future<void> _onPurchasePressed() async {
    final pkg = _selected;
    if (pkg == null || _purchasing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _purchasing = true;
      _errorMessage = null;
    });
    try {
      final success = await _service.purchase(pkg);
      if (!mounted) return;
      if (success) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop(true);
      } else {
        setState(() => _purchasing = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _errorMessage = 'Purchase failed. Please try again.';
      });
    }
  }

  Future<void> _onRestorePressed() async {
    if (_purchasing) return;
    HapticFeedback.selectionClick();
    setState(() {
      _purchasing = true;
      _errorMessage = null;
    });
    final ok = await _service.restore();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _purchasing = false;
      _errorMessage = 'No previous purchases found on this account.';
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildScrollContent(),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: _muted, size: 26),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const SizedBox(height: 8),
        _buildHero(),
        const SizedBox(height: 28),
        _buildValueProps(),
        const SizedBox(height: 28),
        _buildTestimonials(),
        const SizedBox(height: 28),
        _buildPlans(),
        const SizedBox(height: 16),
        _buildErrorBanner(),
        _buildCta(),
        const SizedBox(height: 14),
        _buildFinePrint(),
      ],
    );
  }

  // ─── Hero ───────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_accent, _accentSoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.45),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 18),
        const Text(
          'Unlock FlickClean Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Clean your library faster, free up gigabytes of space, '
          'and keep going without limits.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  // ─── Value props ────────────────────────────────────────────────────────
  Widget _buildValueProps() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          _ValueRow(
            icon: Icons.all_inclusive_rounded,
            title: 'Unlimited swipes',
            subtitle: 'Sort your entire library in one sitting.',
          ),
          SizedBox(height: 14),
          _ValueRow(
            icon: Icons.cleaning_services_rounded,
            title: 'Faster cleanup',
            subtitle: 'Smart batches and instant previews.',
          ),
          SizedBox(height: 14),
          _ValueRow(
            icon: Icons.sd_storage_rounded,
            title: 'Free up storage',
            subtitle: 'Reclaim gigabytes of phone space.',
          ),
          SizedBox(height: 14),
          _ValueRow(
            icon: Icons.update_rounded,
            title: 'All future features',
            subtitle: 'Pro subscribers get every new tool.',
          ),
        ],
      ),
    );
  }

  // ─── Testimonials ───────────────────────────────────────────────────────
  Widget _buildTestimonials() {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _TestimonialCard(
            quote: '“Saved me hours of cleaning my gallery. Worth every cent.”',
            author: 'Sarah M.',
            stars: 5,
          ),
          SizedBox(width: 10),
          _TestimonialCard(
            quote: '“Freed up 14 GB on my phone in one evening.”',
            author: 'Daniel K.',
            stars: 5,
          ),
          SizedBox(width: 10),
          _TestimonialCard(
            quote: '“Finally, photo cleanup that doesn\'t feel like a chore.”',
            author: 'Lena R.',
            stars: 5,
          ),
        ],
      ),
    );
  }

  // ─── Plans ──────────────────────────────────────────────────────────────
  Widget _buildPlans() {
    if (_loadingOfferings) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    final offering = _offering;
    if (offering == null || offering.availablePackages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            const Text(
              'Subscriptions are unavailable right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _loadingOfferings = true;
                  _errorMessage = null;
                });
                _loadOfferings();
              },
              child: const Text('Retry',
                  style: TextStyle(color: _accent, fontSize: 15)),
            ),
          ],
        ),
      );
    }

    final weekly = offering.weekly;
    final monthly = offering.monthly;
    final annual = offering.annual;

    // Order matches conversion-optimised stacking: annual first (biggest
    // value badge), monthly mid, weekly last (smallest commitment).
    final tiles = <Widget>[];
    if (annual != null) {
      tiles.add(_buildPlanTile(
        package: annual,
        title: 'Yearly',
        priceLabel: annual.storeProduct.priceString,
        cadence: 'per year',
        sublabel: _perWeekFromAnnual(annual),
        badge: 'Best value · save 80%',
      ));
    }
    if (monthly != null) {
      tiles.add(_buildPlanTile(
        package: monthly,
        title: 'Monthly',
        priceLabel: monthly.storeProduct.priceString,
        cadence: 'per month',
        badge: 'Most popular',
      ));
    }
    if (weekly != null) {
      tiles.add(_buildPlanTile(
        package: weekly,
        title: 'Weekly',
        priceLabel: weekly.storeProduct.priceString,
        cadence: 'per week',
      ));
    }

    return Column(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          tiles[i],
        ],
      ],
    );
  }

  String? _perWeekFromAnnual(Package annual) {
    final price = annual.storeProduct.price;
    if (price <= 0) return null;
    final perWeek = price / 52.0;
    final code = annual.storeProduct.currencyCode;
    return 'Just $code ${perWeek.toStringAsFixed(2)} / week';
  }

  Widget _buildPlanTile({
    required Package package,
    required String title,
    required String priceLabel,
    required String cadence,
    String? sublabel,
    String? badge,
  }) {
    final selected = _selected?.identifier == package.identifier;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = package);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: selected ? _accent.withOpacity(0.12) : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _accent : const Color(0xFF2C2C2E),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: _accentSoft,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: const TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  cadence,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── CTA ────────────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFF453A), fontSize: 13),
      ),
    );
  }

  Widget _buildCta() {
    final canPurchase = _selected != null && !_purchasing;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canPurchase ? _onPurchasePressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withOpacity(0.4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _purchasing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // ─── Fine print ─────────────────────────────────────────────────────────
  Widget _buildFinePrint() {
    return Column(
      children: [
        const Text(
          'Auto-renews until cancelled. Cancel anytime in your account settings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 11.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FineLink(label: 'Restore', onTap: _onRestorePressed),
            const _FineDot(),
            _FineLink(
              label: 'Terms',
              onTap: () =>
                  _openUrl('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
            ),
            const _FineDot(),
            _FineLink(
              label: 'Privacy',
              onTap: () => _openUrl('https://flickclean.app/privacy'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────
class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF6B4EFF).withOpacity(0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF8B7BFF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                    color: Color(0xFF8E8E93), fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String quote;
  final String author;
  final int stars;
  const _TestimonialCard({
    required this.quote,
    required this.author,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              stars,
              (_) => const Icon(Icons.star_rounded,
                  color: Color(0xFFFFD60A), size: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              quote,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            author,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF6B4EFF) : const Color(0xFF3A3A3C),
          width: 2,
        ),
        color: selected
            ? const Color(0xFF6B4EFF)
            : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _FineLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FineLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FineDot extends StatelessWidget {
  const _FineDot();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text('·', style: TextStyle(color: Color(0xFF3A3A3C))),
    );
  }
}
