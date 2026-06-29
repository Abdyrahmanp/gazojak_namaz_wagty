import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/qibla_calculator.dart';
import '../utils/tk_translations.dart';

class CompassScreen extends StatefulWidget {
  final AppState appState;

  const CompassScreen({super.key, required this.appState});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  final HeadingSmoother _headingSmoother = HeadingSmoother(alpha: 0.1);
  bool _hasVibrated = false;
  double _qiblaBearing = calculateQiblaBearing(gazojakLatitude, gazojakLongitude);
  String _locationLabel = 'Gazojak (deslapky)';
  bool _usingGps = false;
  bool _locationDenied = false;
  bool _compassUnavailable = false;
  Timer? _compassTimeout;

  @override
  void initState() {
    super.initState();
    _initLocation();
    if (FlutterCompass.events == null) {
      _compassUnavailable = true;
    } else {
      _compassTimeout = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _compassUnavailable = true);
      });
    }
  }

  @override
  void dispose() {
    _compassTimeout?.cancel();
    super.dispose();
  }

  void _onCompassDataReceived() {
    if (_compassUnavailable) return;
    _compassTimeout?.cancel();
    _compassTimeout = null;
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;
      setState(() {
        _qiblaBearing = calculateQiblaBearing(position.latitude, position.longitude);
        _usingGps = true;
        _locationLabel = 'GPS: ${position.latitude.toStringAsFixed(2)}°, ${position.longitude.toStringAsFixed(2)}°';
        _locationDenied = false;
      });
      _headingSmoother.reset();
    } catch (_) {
      if (mounted) setState(() => _locationDenied = true);
    }
  }

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
                _locationLabel,
                style: textTheme.bodySmall?.copyWith(color: subColor),
              ),
              if (_locationDenied && !_usingGps) ...[
                const SizedBox(height: 8),
                Text(
                  'Ýerleşiş rugsady berilmedi — Gazojak ugry ulanylýar',
                  style: textTheme.bodySmall?.copyWith(color: Colors.orangeAccent),
                ),
              ],
              const SizedBox(height: 30),

              if (_compassUnavailable || FlutterCompass.events == null)
                _buildNoSensorFallback(textTheme, textColor, subColor, cardBg, borderColor)
              else
                StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildNoSensorFallback(textTheme, textColor, subColor, cardBg, borderColor);
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: AppColors.emeraldGreen),
                              const SizedBox(height: 16),
                              Text(
                                'Kompas gözlenýär...',
                                style: textTheme.bodySmall?.copyWith(color: subColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final rawHeading = snapshot.data?.heading;
                    if (rawHeading == null) {
                      return _buildNoSensorFallback(textTheme, textColor, subColor, cardBg, borderColor);
                    }

                    _onCompassDataReceived();

                  final heading = _headingSmoother.smooth(rawHeading);
                  final headingRad = heading * math.pi / 180.0;
                  final needleRad = (_qiblaBearing - heading) * math.pi / 180.0;

                  var diff = (_qiblaBearing - heading).remainder(360);
                  if (diff > 180) diff -= 360;
                  if (diff < -180) diff += 360;
                  final isAligned = diff.abs() <= 5.0;

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
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
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
                                    ? AppColors.mintGreen.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: isAligned ? 25 : 10,
                                spreadRadius: isAligned ? 4 : 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: -headingRad,
                                child: _buildCompassCard(isDark),
                              ),
                              Transform.rotate(
                                angle: needleRad,
                                child: _buildQiblaNeedle(),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAligned ? AppColors.mintGreen : AppColors.emeraldGreen,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
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

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isAligned
                              ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                              : cardBg,
                          borderRadius: BorderRadius.circular(20),
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
                      ),
                      const SizedBox(height: 20),

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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1),
            ),
          ),
          ...List.generate(72, (index) {
            final angle = index * 5 * math.pi / 180;
            final isCardinal = index % 18 == 0;
            final isSubCardinal = index % 9 == 0 && !isCardinal;

            double length = 8;
            if (isCardinal) {
              length = 16;
            } else if (isSubCardinal) {
              length = 12;
            }

            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: isCardinal ? 2 : 1,
                  height: length,
                  color: isCardinal
                      ? AppColors.emeraldGreen
                      : (isSubCardinal ? labelColor.withValues(alpha: 0.5) : color),
                ),
              ),
            );
          }),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
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
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 30),
            child: const Column(
              children: [
                Icon(Icons.location_on, color: AppColors.amberGlow, size: 32),
                SizedBox(height: 2),
                Icon(Icons.mosque, color: AppColors.amberGlow, size: 18),
              ],
            ),
          ),
        ),
        Container(
          width: 4,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.amberGlow,
                AppColors.amberGlow.withValues(alpha: 0.0),
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
                    padding: EdgeInsets.all(12),
                    child: Text('N', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                ),
                Transform.rotate(
                  angle: _qiblaBearing * math.pi / 180,
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
            ],
          ),
        ),
      ],
    );
  }
}
