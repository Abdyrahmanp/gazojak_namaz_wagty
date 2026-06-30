import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../utils/email_launcher.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';
import '../services/version_service.dart';
import '../config/site_config.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    final launched = await EmailLauncher.open(
      subject: 'Gazojak Namaz Wagty — Goldaw',
      body: 'Kimden: $name\n\n$msg',
    );

    if (!mounted) return;

    if (launched) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(TkTranslations.supportSuccess),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
      _nameCtrl.clear();
      _msgCtrl.clear();
    } else {
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

  void _showAboutDialog(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final sectionBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: bg,
        elevation: isDark ? 24 : 8,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon & Name
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  TkTranslations.aboutTitle,
                  style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Wersiýa ${VersionService.currentVersionName}  •  ${VersionService.currentReleaseDate}',
                  style: TextStyle(color: subColor, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // About Story section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sectionBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    TkTranslations.aboutContent,
                    style: TextStyle(color: textColor, fontSize: 13, height: 1.65),
                  ),
                ),
                const SizedBox(height: 16),

                // Data reliability section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sectionBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppColors.emeraldGreen, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Maglumatlaryň ygtybarlylgy',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Programmadaky namaz wagtlary resmi Türkmenistan dini senenamasy esasynda hasaplanyp, '
                        'Sorag-Jogap bölüminiň mazmunlary ygtybarly dini çeşmeler, din alymlarymyzyň '
                        'eserleri we resmi dini guramalar tarapyndan tassyklanan maglumatlar esasynda taýýarlandy.\n\n'
                        'Eger ýalňyşlyk ýa-da anyklaşdyrylmaly maglumat görseňiz, programmanyň içindäki '
                        '"Habarlaşmak we Goldaw" düwmesi arkaly habar beriň.',
                        style: TextStyle(color: subColor, fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Ýap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final tt = Theme.of(context).textTheme;
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
              // Title
              Text(
                TkTranslations.settingsTitle,
                style: tt.headlineMedium?.copyWith(color: tc, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 20),

              // Toggles card
              _card(
                borderColor,
                cardBg,
                child: Column(
                  children: [
                    _switchTile(
                      icon: isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                      iconColor: isDark ? Colors.amber : AppColors.emeraldGreen,
                      iconBg: isDark ? Colors.amber.withValues(alpha: 0.12) : AppColors.emeraldGreen.withValues(alpha: 0.08),
                      label: TkTranslations.themeSetting,
                      value: isDark,
                      onChanged: (_) {
                        HapticFeedback.selectionClick();
                        widget.appState.toggleTheme();
                      },
                      tt: tt,
                      tc: tc,
                      borderColor: borderColor,
                      showDivider: true,
                    ),
                    _switchTile(
                      icon: Icons.splitscreen_rounded,
                      iconColor: AppColors.emeraldGreen,
                      iconBg: AppColors.emeraldGreen.withValues(alpha: 0.08),
                      label: TkTranslations.persistentNotificationSetting,
                      value: widget.appState.persistentNotificationEnabled,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        widget.appState.togglePersistentNotification(v);
                      },
                      tt: tt,
                      tc: tc,
                      borderColor: borderColor,
                      showDivider: true,
                    ),
                    _switchTile(
                      icon: Icons.volume_up_rounded,
                      iconColor: AppColors.emeraldGreen,
                      iconBg: AppColors.emeraldGreen.withValues(alpha: 0.08),
                      label: TkTranslations.notificationSoundSetting,
                      value: widget.appState.notificationSoundEnabled,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        widget.appState.toggleNotificationSound(v);
                      },
                      tt: tt,
                      tc: tc,
                      borderColor: borderColor,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // About + Legal + Contact Support
              Text('Maglumat', style: tt.titleLarge?.copyWith(color: tc, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _card(
                borderColor,
                cardBg,
                child: Column(
                  children: [
                    // About tap → modal
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.emeraldGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.emeraldGreen),
                      ),
                      title: Text(TkTranslations.aboutTitle, style: tt.titleMedium?.copyWith(color: tc, fontWeight: FontWeight.w600)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: sc),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _showAboutDialog(context, isDark);
                      },
                    ),
                    Divider(color: borderColor, height: 1),
                    // Version Check tile
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.emeraldGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.system_update_alt_rounded, color: AppColors.emeraldGreen),
                      ),
                      title: Text(TkTranslations.versionCheckTitle, style: tt.titleMedium?.copyWith(color: tc, fontWeight: FontWeight.w600)),
                      subtitle: Text('${TkTranslations.currentVersionText}${VersionService.currentVersionName}', style: tt.bodySmall?.copyWith(color: sc)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: sc),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _checkUpdatesManually();
                      },
                    ),
                    Divider(color: borderColor, height: 1),
                    // Legal accordion
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.emeraldGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.gavel_rounded, color: AppColors.emeraldGreen),
                        ),
                        title: Text(TkTranslations.legalTitle, style: tt.titleMedium?.copyWith(color: tc, fontWeight: FontWeight.w600)),
                        iconColor: AppColors.emeraldGreen,
                        collapsedIconColor: sc,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(TkTranslations.privacyTitle, style: tt.bodyLarge?.copyWith(color: tc, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(TkTranslations.privacyContent, style: tt.bodySmall?.copyWith(color: tc, height: 1.5)),
                                const SizedBox(height: 14),
                                Text(TkTranslations.termsTitle, style: tt.bodyLarge?.copyWith(color: tc, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(TkTranslations.termsContent, style: tt.bodySmall?.copyWith(color: tc, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: borderColor, height: 1),
                    // Support Form accordion
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.emeraldGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.mail_outline_rounded, color: AppColors.emeraldGreen),
                        ),
                        title: Text(TkTranslations.supportTitle, style: tt.titleMedium?.copyWith(color: tc, fontWeight: FontWeight.w600)),
                        subtitle: Text(TkTranslations.supportSubtitle, style: tt.bodySmall?.copyWith(color: sc)),
                        iconColor: AppColors.emeraldGreen,
                        collapsedIconColor: sc,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _field(
                                    _nameCtrl,
                                    TkTranslations.supportNameHint,
                                    Icons.person_outline_rounded,
                                    isDark,
                                    validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _field(
                                    _msgCtrl,
                                    TkTranslations.supportMessageHint,
                                    Icons.chat_bubble_outline_rounded,
                                    isDark,
                                    maxLines: 4,
                                    validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _sendEmail,
                                      icon: const Icon(Icons.send_rounded, size: 18),
                                      label: const Text(TkTranslations.supportSubmitBtn, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.emeraldGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.emeraldGreen.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Abdyrahman Döwletgulyýew',
                          style: tt.bodyMedium?.copyWith(
                            color: tc,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dörediji  •  2026',
                      style: tt.bodySmall?.copyWith(color: sc),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openWebsite(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.language_rounded, color: AppColors.emeraldGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              TkTranslations.visitWebsiteTitle,
                              style: tt.bodySmall?.copyWith(
                                color: AppColors.emeraldGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Wersiýa ${VersionService.currentVersionName}',
                        style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWebsite() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(SiteConfig.websiteUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sahypa açylmady. Internet baglanyşygyny barlaň.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Widget _card(Color border, Color bg, {required Widget child}) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: child,
      );

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required TextTheme tt,
    required Color tc,
    required Color borderColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(label, style: tt.titleMedium?.copyWith(color: tc, fontWeight: FontWeight.w600)),
          trailing: Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.emeraldGreen,
            onChanged: (v) => onChanged(v),
          ),
        ),
        if (showDivider) Divider(color: borderColor, height: 1),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.emeraldGreen, size: 20),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _checkUpdatesManually() async {
    final isDark = widget.appState.isDarkMode;
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    // Show checking dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircularProgressIndicator(color: AppColors.emeraldGreen),
              const SizedBox(width: 20),
              Text(
                TkTranslations.checkingUpdates,
                style: TextStyle(color: tc, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    final versionService = VersionService();
    final remoteInfo = await versionService.fetchRemoteVersion();

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (remoteInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(TkTranslations.checkUpdateFailed),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final isUpdateAvail = await versionService.isUpdateAvailable(remoteInfo);
    if (!mounted) return;
    if (!isUpdateAvail) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.emeraldGreen, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  TkTranslations.versionUpToDate,
                  style: TextStyle(color: tc, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${TkTranslations.currentVersionText}${VersionService.currentVersionName}\n'
                  '${TkTranslations.updateDateText}${VersionService.currentReleaseDate}',
                  style: TextStyle(color: sc, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Ýap', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Show update dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: bg,
            elevation: isDark ? 24 : 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: borderColor, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.emeraldGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          TkTranslations.updateTitle,
                          style: TextStyle(
                            color: tc,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${TkTranslations.currentVersionText}${VersionService.currentVersionName}\n'
                    '${TkTranslations.remoteVersionText}${remoteInfo.versionName}\n'
                    '${TkTranslations.updateDateText}${remoteInfo.releaseDate}',
                    style: TextStyle(
                      color: tc,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (remoteInfo.whatsNew.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      TkTranslations.whatsNewText,
                      style: TextStyle(
                        color: tc,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        remoteInfo.whatsNew,
                        style: TextStyle(
                          color: sc,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          TkTranslations.updateLater,
                          style: TextStyle(color: sc, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          final uri = Uri.parse(remoteInfo.apkUrl);
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } catch (_) {}
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          TkTranslations.updateNow,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
