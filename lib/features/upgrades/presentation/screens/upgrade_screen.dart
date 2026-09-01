import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../data/upgrade_store.dart';
import '../../domain/upgrade_catalog.dart';
import '../widgets/upgrade_track_card.dart';

/// The account-wide skill-tree screen. Portrait, scrollable, styled like the
/// main menu: a translucent storybook panel over the menu background. All copy
/// is Vietnamese. Owns no orientation lock — it inherits the menus' portrait
/// state.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  UpgradeState? _state;

  /// Guards against a web double-click firing two concurrent read-modify-writes
  /// (which would spend twice but only bank one tier). Buy buttons are disabled
  /// while set.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await UpgradeStore.load();
    if (!mounted) return;
    setState(() => _state = state);
  }

  Future<void> _buy(UpgradeAxis axis) async {
    if (_busy) return;
    setState(() => _busy = true);
    final bought = await UpgradeStore.buy(axis);
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!bought) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Không nâng cấp được — chưa đủ điểm.')),
        );
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại nâng cấp?'),
        content: const Text(
          'Xoá toàn bộ điểm đã nhận và các bậc đã mua. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await UpgradeStore.reset();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      backgroundColor: const Color(0xFF12321A),
      appBar: AppBar(
        title: const Text('NÂNG CẤP THÁP'),
        backgroundColor: const Color(0xFF164F3B),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      body: state == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/menu/menu_background.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.08),
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: Color(0xFF1A4D32)),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x33123018)),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _panel(state),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _panel(UpgradeState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1D8).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFFFF8DD), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55143F2A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          BoxShadow(color: Color(0x667A5B2E), offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Điểm nâng cấp: ${state.points}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF164F3B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thắng màn mới để nhận thêm điểm. Chơi lại màn cũ không cộng điểm.',
            style: TextStyle(fontSize: 13, color: Color(0xFF5B6F57)),
          ),
          for (final track in kUpgradeCatalog)
            UpgradeTrackCard(
              track: track,
              tier: state.levels.tierOf(track.axis),
              points: state.points,
              busy: _busy,
              onBuy: () => _buy(track.axis),
            ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Align(
              child: TextButton.icon(
                onPressed: _confirmReset,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Đặt lại'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9A5B2E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
