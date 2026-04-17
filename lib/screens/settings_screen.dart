import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _leftHanded;

  @override
  void initState() {
    super.initState();
    _leftHanded = PreferencesService.instance.isLeftHanded;
  }

  Future<void> _setLeftHanded(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _leftHanded = value);
    await PreferencesService.instance.setLeftHanded(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'SWIPE GESTURES',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.fromLTRB(16, 6, 12, 6),
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.back_hand_rounded,
                  color: Color(0xFF6B4EFF),
                  size: 20,
                ),
              ),
              title: const Text(
                'Left-handed mode',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text(
                'Swipe right to delete, left to keep',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                ),
              ),
              value: _leftHanded,
              onChanged: _setLeftHanded,
              activeColor: const Color(0xFF6B4EFF),
            ),
          ),

          const SizedBox(height: 28),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'PREVIEW',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _SwipePreview(
              key: ValueKey(_leftHanded),
              leftHanded: _leftHanded,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFFFD60A), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _leftHanded
                        ? 'Left-handed mode is on. Swipe right to delete, swipe left to keep.'
                        : 'Default mode. Swipe right to keep, swipe left to delete.',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live swipe-direction preview ─────────────────────────────────────────────

class _SwipePreview extends StatelessWidget {
  final bool leftHanded;
  const _SwipePreview({super.key, required this.leftHanded});

  @override
  Widget build(BuildContext context) {
    final leftAction = leftHanded ? _Action.keep : _Action.delete;
    final rightAction = leftHanded ? _Action.delete : _Action.keep;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MockCard(leftAction: leftAction, rightAction: rightAction),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DirectionTile(arrow: '← Left', action: leftAction),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DirectionTile(arrow: 'Right →', action: rightAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Action { keep, delete }

extension _ActionStyle on _Action {
  String get label => this == _Action.keep ? 'KEEP' : 'DELETE';
  Color get color =>
      this == _Action.keep ? const Color(0xFF30D158) : const Color(0xFFFF453A);
  IconData get icon =>
      this == _Action.keep ? Icons.favorite_rounded : Icons.delete_outline_rounded;
}

class _MockCard extends StatelessWidget {
  final _Action leftAction;
  final _Action rightAction;
  const _MockCard({required this.leftAction, required this.rightAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.arrow_back_ios_rounded, color: leftAction.color, size: 22),
        Container(
          width: 100,
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.photo_rounded,
            color: Color(0xFF48484A),
            size: 40,
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, color: rightAction.color, size: 22),
      ],
    );
  }
}

class _DirectionTile extends StatelessWidget {
  final String arrow;
  final _Action action;
  const _DirectionTile({required this.arrow, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: action.color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: action.color.withOpacity(0.22), width: 1),
      ),
      child: Column(
        children: [
          Icon(action.icon, color: action.color, size: 26),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: TextStyle(
              color: action.color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            arrow,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
