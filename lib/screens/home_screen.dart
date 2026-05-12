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
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789'; // A-Z, スペース, 0-9
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
            const Spacer(flex: 1),
            _NicknameEntry(
              alphabet: _alphabet,
              slotCount: _slotCount,
              onChanged: (slot, index) => _indices[slot] = index,
            ),
            const Spacer(flex: 3),
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
/// 各桁は CupertinoPicker の慣性スクロールで A-Z, スペース, 0-9 を選択する。
class _NicknameEntry extends StatefulWidget {
  const _NicknameEntry({
    required this.alphabet,
    required this.slotCount,
    required this.onChanged,
  });

  final String alphabet;
  final int slotCount;
  final void Function(int slot, int index) onChanged;

  @override
  State<_NicknameEntry> createState() => _NicknameEntryState();
}

class _NicknameEntryState extends State<_NicknameEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'ENTER YOUR NAME',
          style: TextStyle(
            color: Colors.amberAccent,
            letterSpacing: 6,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.amber, blurRadius: 12),
            ],
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _arrowController,
          builder: (_, __) {
            final t = Curves.easeInOut.transform(_arrowController.value);
            return Transform.translate(
              offset: Offset(0, t * 6),
              child: Opacity(
                opacity: 0.4 + t * 0.6,
                child: const Text(
                  '▼  ▼  ▼',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    letterSpacing: 4,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int slot = 0; slot < widget.slotCount; slot++)
                Expanded(
                  child: _SlotPicker(
                    alphabet: widget.alphabet,
                    onChanged: (i) => widget.onChanged(slot, i),
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

class _SlotPickerState extends State<_SlotPicker>
    with SingleTickerProviderStateMixin {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController();
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ハイライト枠（中央のセルに重ねる・パルス発光）
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_glowController.value);
                final alpha = 0.3 + t * 0.7;
                return Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.amberAccent.withValues(alpha: alpha),
                          width: 1.5),
                      bottom: BorderSide(
                          color: Colors.amberAccent.withValues(alpha: alpha),
                          width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent
                            .withValues(alpha: alpha * 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                );
              },
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
            // 両方向に無限ループ。A から上スワイプでスペース、下スワイプで B も可
            looping: true,
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
