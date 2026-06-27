import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';

class CompassScreen extends StatefulWidget {
  final AppState appState;

  const CompassScreen({super.key, required this.appState});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  static const double qiblaAngle = 228.3; // Bearing of Makkah from Gazojak
  bool _hasVibrated = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
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
                TkTranslations.qiblaAngleText,
                style: textTheme.bodySmall?.copyWith(color: subColor),
              ),
              const SizedBox(height: 30),

              // Sensor Compass logic via StreamBuilder with 1.5s timeout for offline robustness
              StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events?.timeout(
                  const Duration(milliseconds: 1500),
                  onTimeout: (sink) {
                    sink.addError(TimeoutException("No compass sensor response"));
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildNoSensorFallback(textTheme, textColor, subColor, cardBg, borderColor);
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.emeraldGreen),
                    );
                  }

                  double? heading = snapshot.data?.heading;

                  // If heading is null, it means no magnetometer sensor is detected
                  if (heading == null) {
                    return _buildNoSensorFallback(textTheme, textColor, subColor, cardBg, borderColor);
                  }

                  // Heading is degrees clockwise from North.
                  // Qibla is 228.3 degrees clockwise from North.
                  // Compass Dial should rotate by -heading so North is at top.
                  // Qibla Needle should rotate by (qiblaAngle - heading).
                  double headingRad = heading * (math.pi / 180.0);
                  double qiblaRad = (qiblaAngle - heading) * (math.pi / 180.0);

                  // Calculate difference in degrees (normalized to -180 to 180)
                  double diff = (qiblaAngle - heading).remainder(360);
                  if (diff > 180) diff -= 360;
                  if (diff < -180) diff += 360;
                  bool isAligned = diff.abs() <= 4.0;

                  // Trigger vibration once when entering alignment range
                  if (isAligned) {
                    if (!_hasVibrated) {
                      HapticFeedback.mediumImpact();
                      _hasVibrated = true;
                    }
                  } else {
                    _hasVibrated = false;
                  }

                  return Column(
                    children: [
                      // Compass Frame Stack
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBg,
                            border: Border.all(
                              color: isAligned 
                                  ? AppColors.mintGreen 
                                  : borderColor,
                              width: isAligned ? 3.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isAligned
                                    ? AppColors.mintGreen.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.1),
                                blurRadius: isAligned ? 25 : 10,
                                spreadRadius: isAligned ? 4 : 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Rotating Compass Card (North/South/East/West markings)
                              Transform.rotate(
                                angle: -headingRad,
                                child: _buildCompassCard(isDark),
                              ),

                              // 2. Rotating Qibla Needle
                              Transform.rotate(
                                angle: qiblaRad,
                                child: _buildQiblaNeedle(),
                              ),

                              // 3. Central Cap
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAligned ? AppColors.mintGreen : AppColors.emeraldGreen,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Status Information
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isAligned 
                              ? AppColors.emeraldGreen.withOpacity(0.15) 
                              : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAligned ? AppColors.mintGreen : borderColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isAligned ? TkTranslations.qiblaAligned : "${TkTranslations.qiblaAngleText}°",
                              style: textTheme.titleMedium?.copyWith(
                                color: isAligned ? AppColors.mintGreen : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TkTranslations.qiblaDirectionText,
                              style: textTheme.bodyMedium?.copyWith(color: subColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Calibrate Tip
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.emeraldGreen, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              TkTranslations.compassCalibrateTip,
                              style: textTheme.bodySmall?.copyWith(color: subColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassCard(bool isDark) {
    final color = isDark ? Colors.white30 : Colors.black26;
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner circular border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1),
            ),
          ),
          // Tick lines representing directions
          ...List.generate(72, (index) {
            final angle = index * 5 * math.pi / 180;
            final isCardinal = index % 18 == 0; // 0, 90, 180, 270 deg
            final isSubCardinal = index % 9 == 0 && !isCardinal;
            
            double length = 8;
            if (isCardinal) length = 16;
            else if (isSubCardinal) length = 12;

            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: isCardinal ? 2 : 1,
                  height: length,
                  color: isCardinal 
                      ? AppColors.emeraldGreen 
                      : (isSubCardinal ? labelColor.withOpacity(0.5) : color),
                ),
              ),
            );
          }),
          // Direction letters
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: const Text(
                'N',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                'S',
                style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(
                'E',
                style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                'W',
                style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaNeedle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The Needle Pointer (an elegant arrow pointing to Makkah)
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                // Arrow tip
                const Icon(
                  Icons.location_on,
                  color: AppColors.amberGlow,
                  size: 32,
                ),
                // Kaaba Icon or Marker
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mosque,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Connecting line
        Container(
          width: 4,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.amberGlow,
                AppColors.amberGlow.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoSensorFallback(
    TextTheme textTheme,
    Color textColor,
    Color subColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Static Graphic representing target direction
        Center(
          child: Container(
            width: 220,
            height: 220,
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
                    padding: EdgeInsets.all(12.0),
                    child: Text('N (Demirgazyk)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                ),
                Transform.rotate(
                  angle: qiblaAngle * math.pi / 180,
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 25),
                        Icon(Icons.location_on, color: AppColors.amberGlow, size: 40),
                        Text('Kybla', style: TextStyle(color: AppColors.amberGlow, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.perm_device_information_rounded, color: AppColors.emeraldGreen, size: 36),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Information box explaining qibla direction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.amberGlow, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kybla görkezijisi elýetersiz',
                      style: textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                TkTranslations.compassWarning,
                style: textTheme.bodyMedium?.copyWith(color: subColor),
              ),
              const SizedBox(height: 16),
              _buildBulletPoint("${TkTranslations.qiblaAngleText}°", textTheme, textColor),
              const SizedBox(height: 8),
              _buildBulletPoint(TkTranslations.qiblaDirectionText, textTheme, textColor),
              const SizedBox(height: 8),
              _buildBulletPoint("Ýerleşiş: Demirgazyga garanyňyzda çep egnik tarapyňyzda 228.3° burçda durýar (Günbatardan azajyk günorta tarap).", textTheme, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, TextTheme textTheme, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 16)),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
