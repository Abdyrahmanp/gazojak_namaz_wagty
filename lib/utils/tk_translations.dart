class TkTranslations {
  // ── Prayer name maps ────────────────────────────────────────────────────────
  static const Map<String, String> prayerNames = {
    'bamdat': 'Ertir',
    'gun':    'Günüň dogmagy',
    'oyle':   'Öýle',
    'ikindi': 'Ikindi',
    'agsam':  'Agşam',
    'yasy':   'Ýassy',
  };

  static const Map<String, String> prayerNamesShort = {
    'bamdat': 'Ertir',
    'gun':    'Gün dogmagy',
    'oyle':   'Öýle',
    'ikindi': 'Ikindi',
    'agsam':  'Agşam',
    'yasy':   'Ýassy',
  };

  // ── Calendar ────────────────────────────────────────────────────────────────
  static const List<String> months = [
    '',
    'Ýanwar', 'Fewral', 'Mart', 'Aprel',
    'Maý', 'Iýun', 'Iýul', 'Awgust',
    'Sentýabr', 'Oktýabr', 'Noýabr', 'Dekabr',
  ];

  static const List<String> monthsShort = [
    '',
    'Ýan', 'Few', 'Mar', 'Apr',
    'Maý', 'Iýn', 'Iýl', 'Awg',
    'Sen', 'Okt', 'Noý', 'Dek',
  ];

  static const Map<int, String> weekdays = {
    1: 'Duşenbe',  2: 'Sişenbe', 3: 'Çarşenbe',
    4: 'Penşenbe', 5: 'Anna',    6: 'Şenbe', 7: 'Ýekşenbe',
  };

  // Short weekday headers (Mon-first order, index 0 = Monday)
  static const List<String> weekdayHeaders = [
    'Du', 'Si', 'Ça', 'Pe', 'An', 'Şe', 'Ýe',
  ];

  // ── Generic UI ──────────────────────────────────────────────────────────────
  static const String appTitle           = 'Gazojak Namaz Wagty';
  static const String cityHeader         = 'Gazojak şäheri';
  static const String nextPrayerLabel    = 'Indiki Namaz';
  static const String remainingTimeLabel = 'Galan wagt';
  static const String passedTimeLabel    = 'Wagty doldy';

  // ── Navigation ──────────────────────────────────────────────────────────────
  static const String navHome     = 'Wagtlar';
  static const String navCompass  = 'Kybla';
  static const String navTasbih  = 'Tesbih';
  static const String navFAQ     = 'Sorag-Jogap';
  static const String navSettings = 'Sazlamalar';

  // ── Compass ─────────────────────────────────────────────────────────────────
  static const String compassTitle         = 'Kybla Ugry';
  static const String compassWarning       = 'Telefonyňyzyň kompas sensory ýok ýa-da işlemeýär. Aşakdaky görkezijä görä ugry anyklap bilersiňiz:';
  static const String qiblaAngleText       = 'Gazojak üçin Kybla burçy: 228.3°';
  static const String qiblaDirectionText   = 'Ugry: Günbatar-Günorta-Günbatar (WSW)';
  static const String qiblaAligned         = 'Kybla tarapa öwrüldiňiz!';
  static const String compassCalibrateTip  = 'Dogry görkezmegi üçin telefonyňyzy tekiz saklaň we 8 görnüşinde aýlap görüň.';

  // ── FAQ / Islamic Guide ──────────────────────────────────────────────────────
  static const String faqTitle    = 'Sorag-Jogap';
  static const String faqSubtitle = 'Dini gollanmalar we goldaw';
  static const String faqPlaceholderTitle = 'Sorag-Jogap bölümi täzelenýär';
  static const String faqPlaceholderContent = 'Häzirki wagtda programmanyň bu bölümi düýpli täzelenme tapgyryndan geçýär. Siz üçin has takyk, peýdaly we ynamdar dini maglumatlary hem-de köp soralýan sorag-jogaplary taýýarlaýarys. Täze maglumatlar ýakyn wagtda elýeterli bolar. Düşünjegiňiz we sabyrlylygyňyz üçin sag boluň!';

  static const String jumaTitle = 'Juma Namazy nähili okalýar?';
  static const String jumaContent =
      'Juma namazy jemi 10 rekatdyr:\n\n'
      '1. Ilki 4 rekat Juma namazynyň ilkinji sünneti okalýar.\n'
      '2. Soňra ymamyň yzysüre 2 rekat parz okalýar. Ymam farzy açyk okaýar, biz diňleýäris.\n'
      '3. Parzdan soňra 4 rekat soňky sünnet okalýar.\n\n'
      'Juma namazyny okamak her bir akyly-başynda bolan, azat, sagdyn we ýolagçy bolmadyk erkege parzdyr.';

  static const String eidTitle = 'Baýram Namazy nähili okalýar?';
  static const String eidContent =
      'Oraza we Gurban baýramy namazlary 2 rekatdyr, jemagat bilen okalýar:\n\n'
      '1. Birinji rekatda niýet edilip yftytah tekbiri alynýar. Subhaneke okalýar. '
      'Ymam sesli 3 gezek tekbir aýdýar, eller gulaklara galdyrylyp aşak goýberilýär. '
      '4-nji tekbirde eller gowşurylýar. Ymam Fatiha we sura okaýar, ruku we sejde edilýär.\n'
      '2. Ikinji rekatda ymam sura okaýar. Rukua gitmezden öň 3 gezek tekbir — '
      '4-njysynda göni rukua gidilýär.\n'
      '3. Sejdelerden soň oturylyp salam berilýär. Namazdan soň hutbe diňlenilýär.\n\n'
      'Baýram namazyny okamak wajypdyr.';

  // ── Contact / Support ────────────────────────────────────────────────────────
  static const String supportTitle      = 'Habarlaşmak we Goldaw';
  static const String supportSubtitle   = 'Hata habar bermek, dini soraglar ýa-da teklip üçin ýazyň';
  static const String supportNameHint   = 'Adyňyz';
  static const String supportEmailHint  = 'E-poçtaňyz';
  static const String supportMessageHint = 'Hatyňyz…';
  static const String supportSubmitBtn  = 'Hat ugrat';
  static const String supportSuccess    = 'E-poçta programmasy açyldy. Hatyňyzy ugradyp bilersiňiz!';
  static const String emailLaunchFailed = 'E-poçta programmasy açylmady. Gmail ýa-da başga e-poçta programmasyny gurnaň.';
  static const String shareVia          = 'Paýlaş';
  static const String supportError      = 'Ähli meýdançalary dogry dolduryň.';

  // ── Legal ────────────────────────────────────────────────────────────────────
  static const String legalTitle    = 'Düzgünler we Syýasat';
  static const String privacyTitle  = 'Gizlinlik Syýasaty';
  static const String privacyContent =
      'Bu programma ulanyjylardan hiç hili şahsy maglumat ýygnamaýar we paýlaşmaýar. '
      'Bütinleý internetsiz we howpsuz işlemek üçin niýetlenendir.';
  static const String termsTitle   = 'Ulanyş Şertleri';
  static const String termsContent =
      'Programmadaky namaz wagtlamalary ýörite Gazojak şäheri üçin taýýarlandy. '
      'Programma diňe maglumat bermek maksady bilen hyzmat edýär.';

  // ── Tasbih ──────────────────────────────────────────────────────────────────
  static const String tasbihTitle  = 'Tesbih';
  static const String targetCount  = 'Maksat';
  static const String totalCount   = 'Jemi';
  static const String resetLabel   = 'Nol et';
  static const String selectZikir  = 'Zikir saýlaň';

  static const List<String> defaultDhikrs = [
    'Subhanallah (Alla ähli kemçiliklerden päkdir)',
    'Alhamdulillah (Ähli öwgüler Alla degişlidir)',
    'Allahu Akbar (Alla iň Beýikdir)',
    'Lä ilähe illallah',
    'Astagfirullah',
    'Subhanallahi we bihamdihi',
    'La hawla wala quwwata illa billah',
  ];

  static const List<String> shortDhikrs = [
    'Subhanallah',
    'Alhamdulillah',
    'Allahu Akbar',
    'Lä ilähe illallah',
    'Astagfirullah',
    'Subhanallahi we bihamdihi',
    'La hawla wala quwwata',
  ];

  // ── Settings ─────────────────────────────────────────────────────────────────
  static const String settingsTitle                = 'Sazlamalar';
  static const String themeSetting                 = 'Garaňky tema';
  static const String notificationSoundSetting     = 'Bildiriş sesleri';
  static const String persistentNotificationSetting = 'Yzygiderli wagtlar paneli';
  static const String offsetSetting               = 'Wagtlary sazlamak (goşmaça)';
  static const String offsetExplain               = 'Programmanyň wagtlary resmi senenama esasynda takyk. Diňe metjidiňiz başga wagt görkezýän bolsa, bu ýerden sazlap bilersiňiz.';
  static const String minutesSuffix               = 'minut';
  static const String aboutTitle                  = 'Biz Barada';
  static const String appVersion                  = 'Wersiýa 1.0.0';

  static const String aboutContent =
      'Bu programma, Gazojak şäherimizdäki musulman doganlarymyzyň namaz wagtlaryna iň dogry we iň çalt usulda ýetip bilmekleri, dini soraglaryna ygtybarly jogaplar tapyp bilmekleri maksady bilen taýýarlandy. Maksadymyz, tehnologiýany haýyrly bir wesaýata öwrüp, durmuşymyzy aňsatlaşdyrmakdyr.\n\n'
      'Programmadaky namaz wagtlary we dini sorag-jogap mazmunlary, resmi we ygtybarly dini çeşmeler esasynda taýýarlandy. Göwün rahatlygy bilen ulanyp bilersiňiz.\n\n'
      'Eger nähilidir bir ýalňyşlyk görseňiz, bize bildirmegiňizi haýyş edýäris.';

  // ── Version Check ────────────────────────────────────────────────────────────
  static const String updateTitle           = 'Täze wersiýa bar!';
  static const String updateLater           = 'Soňra';
  static const String updateNow             = 'Şu wagt täzele';
  static const String versionCheckTitle     = 'Wersiýany barlamak';
  static const String checkingUpdates       = 'Täzelemeler barlanýar...';
  static const String versionUpToDate       = 'Programmaňyz iň soňky wersiýada.';
  static const String currentVersionText    = 'Häzirki wersiýa: ';
  static const String remoteVersionText     = 'Täze wersiýa: ';
  static const String updateDateText        = 'Täzelenen senesi: ';
  static const String whatsNewText          = 'Näme täzelendi:';
  static const String checkUpdateFailed     = 'Täzelemeleri barlap bolmady. Baglanyşygy barlaň.';
  static const String visitWebsiteTitle     = 'Sahypamyza girmek';
  static const String visitWebsiteSubtitle  = 'Programmany göçürip almak we maglumat';
  static const String faqSyncSuccess        = 'Maglumatlar üstünlikli täzelendi!';
  static const String faqSyncFailed         = 'Täzeläp bolmady. Internet baglanyşygyny barlaň.';

  // ── Q&A Feedback ─────────────────────────────────────────────────────────────
  static const String qaReportError         = 'Maglumatda ýalňyşlyk barmy? Bize bildiriň';
  static const String qaRecommendTitle      = 'Siziň üçin';
  static const String qaFeedbackPrompt      = 'Soragyňyzy tapmadyňyzmy? Bize sorag ugradyň';
  static const String qaNoResultsPrompt     = 'Gözlän soragyňyz tapylmady. Bize sorag ugradyň';
  static const String qaSubmitTitle         = 'Täze sorag ugratmak';
  static const String qaSubmitBtn           = 'Soragy ugrat';

  // ── Notification ─────────────────────────────────────────────────────────────
  static const String notificationTitle = 'Namaz Wagty Geldi!';
  static const String notificationBody  = 'Gazojak şäherinde %s wagty girdi.';

  // ── Date helper ──────────────────────────────────────────────────────────────
  static String formatFullDate(DateTime date) {
    final day     = date.day.toString();
    final month   = months[date.month];
    final year    = date.year.toString();
    final weekday = weekdays[date.weekday] ?? '';
    return '$day $month $year, $weekday';
  }
}

