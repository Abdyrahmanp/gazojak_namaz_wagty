import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../utils/email_launcher.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';
import '../models/faq_item.dart';
import '../services/faq_service.dart';
import '../config/site_config.dart';
import 'faq_detail_screen.dart';

class FaqScreen extends StatefulWidget {
  final AppState appState;

  const FaqScreen({super.key, required this.appState});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final FaqService _faqService = FaqService();
  List<FaqCategory> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = 'Ählisi';
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData().then((_) {
      // Background check for updates without showing loaders
      _syncWithServer(silent: true);
    });
  }

  Future<void> _loadLocalData() async {
    final data = await _faqService.loadFaqData();
    if (mounted) {
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithServer({bool silent = false, String? customUrl}) async {
    if (_isUpdating) return;
    
    if (!silent) {
      setState(() {
        _isUpdating = true;
      });
    }
    
    final success = await _faqService.updateFaqDataFromServer(customUrl: customUrl);
    
    if (success) {
      await _loadLocalData();
      if (mounted && !silent) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Color(0xFFCBD5E1)),
                SizedBox(width: 8),
<<<<<<< HEAD
                Text(TkTranslations.faqSyncSuccess, style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold)),
=======
                Text(
                  TkTranslations.faqSyncSuccess,
                  style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold),
                ),
>>>>>>> gecici-dal
              ],
            ),
            backgroundColor: AppColors.emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      if (mounted && !silent) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: Color(0xFFCBD5E1)),
                SizedBox(width: 8),
<<<<<<< HEAD
                Text(TkTranslations.faqSyncFailed, style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold)),
=======
                Text(
                  TkTranslations.faqSyncFailed,
                  style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold),
                ),
>>>>>>> gecici-dal
              ],
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showSyncSettingsDialog() async {
    final currentUrl = await _faqService.getRemoteUrl();
    final urlController = TextEditingController(text: currentUrl);
    
    if (!mounted) return;
    final isDark = widget.appState.isDarkMode;
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showDialog(
      context: context,
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
                        Icons.sync_rounded,
                        color: AppColors.emeraldGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Maglumatlary täzelemek',
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
                  'Ulgamdaky maglumatlary internet arkaly täzelemek üçin aşakdaky çeşme baglanyşygyny üýtgedip bilersiňiz. Täze maglumatlar bu çeşmeden çekilip, offline ýazylar.',
                  style: TextStyle(
                    color: sc,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  style: TextStyle(color: tc, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Maglumat baglanyşygy (JSON URL)',
                    hintText: SiteConfig.faqJsonUrl,
                    labelStyle: const TextStyle(color: AppColors.emeraldGreen, fontSize: 12),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        urlController.text = FaqService.defaultRemoteUrl;
                      },
                      child: const Text(
                        'Aslyna gaýtar',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Ýap',
                            style: TextStyle(color: sc, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final newUrl = urlController.text.trim();
                            if (newUrl.isNotEmpty) {
                              await _faqService.setRemoteUrl(newUrl);
                              if (context.mounted) Navigator.pop(context);
                              _syncWithServer(customUrl: newUrl);
                            }
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
                          child: const Text('Täzele', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
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

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'mosque':
        return Icons.mosque_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.question_answer_rounded;
    }
  }

  String _getIconNameForItem(FaqItem item) {
    for (final category in _categories) {
      if (category.items.contains(item)) {
        return category.icon;
      }
    }
    return '';
  }

  String normalizeTurkmenText(String text) {
    return text.toLowerCase()
        .replaceAll('ä', 'a')
        .replaceAll('ü', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ň', 'n')
        .replaceAll('ž', 'z')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o');
  }

  void _showSubmitQuestionBottomSheet() {
    final isDark = widget.appState.isDarkMode;
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final questionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TkTranslations.qaSubmitTitle,
                      style: TextStyle(
                        color: tc,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: sc),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  style: TextStyle(color: tc),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.emeraldGreen),
                    hintText: TkTranslations.supportNameHint,
                    hintStyle: TextStyle(color: sc.withOpacity(0.5)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: questionCtrl,
                  style: TextStyle(color: tc),
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Soragyňyzy ýazyň' : null,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.help_outline_rounded, color: AppColors.emeraldGreen),
                    hintText: 'Soragyňyz...',
                    hintStyle: TextStyle(color: sc.withOpacity(0.5)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final name = nameCtrl.text.trim().isEmpty ? 'Ulanyjy' : nameCtrl.text.trim();
                      final question = questionCtrl.text.trim();

                      final launched = await EmailLauncher.open(
                        subject: 'Gazojak Namaz Wagty — Täze Sorag',
                        body: 'Kimden: $name\n\nSoragyňyz:\n$question',
                      );

                      if (!context.mounted) return;
                      if (launched) {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      } else {
                        HapticFeedback.vibrate();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              TkTranslations.emailLaunchFailed,
                              style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.orangeAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      TkTranslations.qaSubmitBtn,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitQuestionFooterCard(BuildContext context, bool isDark) {
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.emeraldGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.emeraldGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  TkTranslations.qaFeedbackPrompt,
                  style: TextStyle(
                    color: tc,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showSubmitQuestionBottomSheet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(TkTranslations.qaSubmitBtn, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  List<FaqItem> _getFilteredItems() {
    final List<FaqItem> items = [];
    final normalizedQuery = normalizeTurkmenText(_searchQuery);
    
    for (final category in _categories) {
      if (_selectedCategory == 'Ählisi' || category.category == _selectedCategory) {
        for (final item in category.items) {
          final normalizedQuestion = normalizeTurkmenText(item.question);
          final normalizedAnswer = normalizeTurkmenText(item.answer);
          final matchesSearch = normalizedQuestion.contains(normalizedQuery) ||
              normalizedAnswer.contains(normalizedQuery);
          if (matchesSearch) {
            items.add(item);
          }
        }
      }
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    // Build the category list starting with 'Ählisi'
    final List<String> categoryList = ['Ählisi'];
    for (final cat in _categories) {
      if (cat.category.isNotEmpty && !categoryList.contains(cat.category)) {
        categoryList.add(cat.category);
      }
    }

    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TkTranslations.faqTitle,
                        style: textTheme.headlineMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unudylan sünnetler we köp soralýanlar',
                        style: textTheme.bodyMedium?.copyWith(color: subColor),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _showSyncSettingsDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.emeraldGreen,
                            ),
                          )
                        : const Icon(
                            Icons.sync_rounded,
                            color: AppColors.emeraldGreen,
                            size: 20,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Gözleg...',
                    hintStyle: TextStyle(color: subColor.withValues(alpha: 0.7)),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emeraldGreen),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: subColor),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories Selector
              if (!_isLoading && categoryList.length > 1)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryList.length,
                    itemBuilder: (context, index) {
                      final cat = categoryList[index];
                      final isSelected = _selectedCategory == cat;
                      
                      // Map icon for category if it exists
                      IconData? icon;
                      if (cat != 'Ählisi') {
                        final foundCat = _categories.firstWhere((element) => element.category == cat);
                        icon = _getCategoryIcon(foundCat.icon);
                      } else {
                        icon = Icons.all_inclusive_rounded;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.activePrayerGradient : null,
                              color: isSelected ? null : cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : borderColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.emeraldGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : textColor,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Question List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.emeraldGreen,
                        ),
                      )
                      : RefreshIndicator(
                          color: AppColors.emeraldGreen,
                          onRefresh: () => _syncWithServer(silent: false),
                          child: filteredItems.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                                  children: [
                                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.find_in_page_rounded,
                                              size: 48,
                                              color: AppColors.emeraldGreen,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            TkTranslations.qaNoResultsPrompt,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              HapticFeedback.mediumImpact();
                                              _showSubmitQuestionBottomSheet();
                                            },
                                            icon: const Icon(Icons.mail_outline_rounded, size: 18),
                                            label: const Text(TkTranslations.qaSubmitBtn, style: TextStyle(fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.emeraldGreen,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                                  itemCount: filteredItems.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == filteredItems.length) {
                                      return _buildSubmitQuestionFooterCard(context, isDark);
                                    }
                                    final allDbItems = _categories.expand((cat) => cat.items).toList();
                                    return FaqItemCard(
                                      item: filteredItems[index],
                                      categoryIcon: _getCategoryIcon(_getIconNameForItem(filteredItems[index])),
                                      isDark: isDark,
                                      allItems: allDbItems,
                                      appState: widget.appState,
                                    );
                                  },
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

class FaqItemCard extends StatelessWidget {
  final FaqItem item;
  final IconData categoryIcon;
  final bool isDark;
  final List<FaqItem> allItems;
  final AppState appState;

  const FaqItemCard({
    super.key,
    required this.item,
    required this.categoryIcon,
    required this.isDark,
    required this.allItems,
    required this.appState,
  });

  String _answerPreview(String answer) {
    final flat = answer.replaceAll('\n', ' ').trim();
    if (flat.length <= 110) return flat;
    return '${flat.substring(0, 110)}…';
  }

  @override
  Widget build(BuildContext context) {
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FaqDetailScreen(
                  appState: appState,
                  item: item,
                  allItems: allItems,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    color: AppColors.emeraldGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.question,
                        style: TextStyle(
                          color: tc,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _answerPreview(item.answer),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sc,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Doly oka →',
                        style: TextStyle(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: sc.withValues(alpha: 0.5),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
