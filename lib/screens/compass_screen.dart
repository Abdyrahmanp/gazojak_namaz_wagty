import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';

const double gazojakQiblaBearing = 228.3;

class CompassScreen extends StatefulWidget {
  final AppState appState;

  const CompassScreen({super.key, required this.appState});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  static const double _qiblaBearing = gazojakQiblaBearing;

  StreamSubscription<CompassEvent>? _compassSub;
  double _heading = 0;
  bool _hasSensor = false;
  bool _sensorChecked = false;
  bool _hasVibrated = false;

  @override
  void initState() {
    super.initState();
    _startCompass();
  }

  void _startCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _sensorChecked = true);
      return;
    }

    _compassSub = stream.listen(
      (event) {
        final raw = event.heading;
        if (raw == null) return;

        final normalized = ((raw % 360) + 360) % 360;

        // Ani sıçramaları filtrele (magnetik gürültü)
        if (_hasSensor) {
          var jump = normalized - _heading;
          if (jump > 180) jump -= 360;
          if (jump < -180) jump += 360;
          if (jump.abs() > 45) return;
        }

        if (!mounted) return;
        setState(() {
          _hasSensor = true;
          _sensorChecked = true;
          _heading = normalized;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _sensorChecked = true);
      },
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_sensorChecked) {
        setState(() => _sensorChecked = true);
      }
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  double get _alignmentDiff {
    var diff = (_qiblaBearing - _heading).remainder(360);
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  bool get _isAligned => _hasSensor && _alignmentDiff.abs() <= 4.0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    if (_isAligned) {
      if (!_hasVibrated) {
        HapticFeedback.mediumImpact();
        _hasVibrated = true;
      }
    } else {
      _hasVibrated = false;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TkTranslations.compassTitle,
                style: textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gazojak şäheri · $_qiblaBearing°',
                style: textTheme.bodySmall?.copyWith(color: subColor),
              ),
              const SizedBox(height: 30),
              if (_hasSensor)
                _buildLiveCompass(
                  isDark, textTheme, textColor, subColor, cardBg, borderColor,
                )
              else
                _buildStaticCompass(
                  textTheme, textColor, subColor, cardBg, borderColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCompass(
    bool isDark,
    TextTheme textTheme,
    Color textColor,
    Color subColor,
    Color cardBg,
    Color borderColor,
  ) {
    final headingRad = _heading * math.pi / 180.0;
    final qiblaRad = _qiblaBearing * math.pi / 180.0;
    final diff = _alignmentDiff;
    final isAligned = _isAligned;

    return Column(
      children: [
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(
                color: isAligned ? AppColors.mintGreen : borderColor,
                width: isAligned ? 3.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAligned
                      ? AppColors.mintGreen.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isAligned ? 20 : 8,
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -headingRad,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildCompassCard(isDark),
                  Transform.rotate(
                    angle: qiblaRad,
                    child: _buildQiblaNeedle(),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAligned ? AppColors.mintGreen : AppColors.emeraldGreen,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildStatusBox(
          textTheme, textColor, subColor, cardBg, borderColor,
          isAligned: isAligned,
          diff: diff,
        ),
        const SizedBox(height: 16),
        _buildTip(subColor, textTheme),
      ],
    );
  }

  Widget _buildStaticCompass(
    TextTheme textTheme,
    Color textColor,
    Color subColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _qiblaBearing * math.pi / 180,
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 36),
                      child: Icon(
                        Icons.navigation_rounded,
                        color: AppColors.amberGlow,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.emeraldGreen,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            'Kompas sensory elýetersiz. Telefonyňyzy tekiz saklaň. '
            'Kybla ugry: Demirgazyk (N) üstde bolanda, nyşan $_qiblaBearing° burçda.',
            style: textTheme.bodyMedium?.copyWith(color: subColor, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        _buildTip(subColor, textTheme),
      ],
    );
  }

  Widget _buildStatusBox(
    TextTheme textTheme,
    Color textColor,
    Color subColor,
    Color cardBg,
    Color borderColor, {
    required bool isAligned,
    required double diff,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isAligned
            ? AppColors.emeraldGreen.withValues(alpha: 0.15)
            : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAligned ? AppColors.mintGreen : borderColor,
        ),
      ),
      child: Text(
        isAligned
            ? TkTranslations.qiblaAligned
            : 'Kybla ugry: ${diff.abs().toStringAsFixed(0)}° ${diff > 0 ? 'saga' : 'çepe'} öwrüň',
        textAlign: TextAlign.center,
        style: textTheme.titleMedium?.copyWith(
          color: isAligned ? AppColors.mintGreen : textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTip(Color subColor, TextTheme textTheme) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.emeraldGreen, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            TkTranslations.compassCalibrateTip,
            style: textTheme.bodySmall?.copyWith(color: subColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCompassCard(bool isDark) {
    final tickColor = isDark ? Colors.white24 : Colors.black12;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tickColor, width: 1),
            ),
          ),
          ...List.generate(36, (index) {
            final angle = index * 10 * math.pi / 180;
            final isCardinal = index % 9 == 0;
            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: isCardinal ? 2 : 1,
                  height: isCardinal ? 14 : 8,
                  color: isCardinal ? AppColors.emeraldGreen : tickColor,
                ),
              ),
            );
          }),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'S',
                style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Text('E', style: TextStyle(color: labelColor, fontWeight: FontWeight.bold)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text('W', style: TextStyle(color: labelColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaNeedle() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            child: Container(
              width: 4,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.amberGlow,
                    AppColors.amberGlow.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 16,
            child: Icon(Icons.navigation_rounded, color: AppColors.amberGlow, size: 36),
          ),
        ],
      ),
    );
  }
}
