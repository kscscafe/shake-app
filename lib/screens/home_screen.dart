import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'measure_screen.dart';
import 'ranking_screen.dart';

/// ホーム画面：ニックネーム入力（6文字 A-Z 0-9・iOS ピッカー風ドラムロール）+ SHAKE ボタン
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '; // A-Z, 0-9, space
  static const _slotCount = 6;
  final List<int> _indices = List<int>.filled(_slotCount, 0);

  String get _nickname => _indices.map((i) => _alphabet[i]).join();

  void _onShakePressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasureScreen(nickname: _nickname),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'SHAKE',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
                shadows: [
                  Shadow(color: Color(0xFF15803D), blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SHAKE TO THE WORLD',
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 4,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            _NicknameEntry(
              alphabet: _alphabet,
              slotCount: _slotCount,
              onChanged: (slot, index) => _indices[slot] = index,
            ),
            const SizedBox(height: 32),
            _ShakeButton(onPressed: _onShakePressed),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RankingScreen(),
                ),
              ),
              child: const Text(
                'WORLD RANKING ▶',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// ニックネーム入力（iOS ピッカー風ドラムロール）。
class _NicknameEntry extends StatelessWidget {
  const _NicknameEntry({
    required this.alphabet,
    required this.slotCount,
    required this.onChanged,
  });

  final String alphabet;
  final int slotCount;
  final void Function(int slot, int index) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'ENTER YOUR NAME',
          style: TextStyle(
            color: Colors.amberAccent,
            letterSpacing: 6,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int slot = 0; slot < slotCount; slot++)
                Expanded(
                  child: _SlotPicker(
                    alphabet: alphabet,
                    onChanged: (i) => onChanged(slot, i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotPicker extends StatefulWidget {
  const _SlotPicker({required this.alphabet, required this.onChanged});

  final String alphabet;
  final ValueChanged<int> onChanged;

  @override
  State<_SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<_SlotPicker> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Colors.amberAccent.withValues(alpha: 0.5)),
                  bottom: BorderSide(
                      color: Colors.amberAccent.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          CupertinoPicker(
            scrollController: _controller,
            itemExtent: 44,
            useMagnifier: true,
            magnification: 1.15,
            squeeze: 1.1,
            diameterRatio: 1.2,
            backgroundColor: Colors.transparent,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: widget.onChanged,
            children: [
              for (final c in widget.alphabet.split(''))
                Center(
                  child: Text(
                    c,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShakeButton extends StatelessWidget {
  const _ShakeButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF22C55E), Color(0xFF14532D)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0xFF16A34A), blurRadius: 16),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'SHAKE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
