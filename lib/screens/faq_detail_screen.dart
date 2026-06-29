import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state.dart';
import '../models/faq_item.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';
import '../utils/email_launcher.dart';

class FaqDetailScreen extends StatefulWidget {
  final AppState appState;
  final FaqItem item;
  final List<FaqItem> allItems;

  const FaqDetailScreen({
    super.key,
    required this.appState,
    required this.item,
    required this.allItems,
  });

  @override
  State<FaqDetailScreen> createState() => _FaqDetailScreenState();
}

class _FaqDetailScreenState extends State<FaqDetailScreen> {
  late final List<FaqItem> _recommendations;

  @override
  void initState() {
    super.initState();
    final others = widget.allItems
        .where((x) => x.question != widget.item.question)
        .toList();
    others.shuffle();
    _recommendations = others.take(3).toList();
  }

  Future<void> _shareContent() async {
    final text =
        'Sorag: ${widget.item.question}\n\nJogap: ${widget.item.answer}\n\n— Gazojak Namaz Wagty programmasy';
    HapticFeedback.mediumImpact();
    await Share.share(text, subject: widget.item.question);
  }

  Future<void> _reportError(BuildContext context) async {
    final launched = await EmailLauncher.open(
      subject: 'Gazojak Namaz Wagty — Ýalňyşlyk Bildirişi',
      body: 'Sorag: ${widget.item.question}\n\nÝalňyşlyk barada düşündiriş:\n',
    );
    if (!launched && context.mounted) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TkTranslations.emailLaunchFailed),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final bgGradient = isDark
        ? AppColors.darkBackgroundGradient
        : AppColors.lightBackgroundGradient;

    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: borderColor),
                        ),
                      ),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: tc, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        TkTranslations.faqTitle,
                        style: TextStyle(
                          color: tc,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _shareContent,
                      tooltip: TkTranslations.shareVia,
                      style: IconButton.styleFrom(
                        backgroundColor: cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: borderColor),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, color: AppColors.emeraldGreen, size: 20),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.activePrayerGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          widget.item.question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                            Text(
                              widget.item.answer,
                              style: TextStyle(
                                color: tc,
                                fontSize: 15,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(color: borderColor),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _reportError(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent.withValues(alpha: 0.8),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        TkTranslations.qaReportError,
                                        style: TextStyle(
                                          color: sc,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: sc.withValues(alpha: 0.5),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (_recommendations.isNotEmpty) ...[
                        Text(
                          TkTranslations.qaRecommendTitle,
                          style: TextStyle(
                            color: tc,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._recommendations.map((recItem) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FaqDetailScreen(
                                      appState: widget.appState,
                                      item: recItem,
                                      allItems: widget.allItems,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        recItem.question,
                                        style: TextStyle(
                                          color: tc,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppColors.emeraldGreen,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
