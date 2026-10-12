; ═══════════════════════════════════════════════════════════════════════════
; مثبِّت نظام سند لويندوز — Inno Setup 6
; ═══════════════════════════════════════════════════════════════════════════
;
; ⚠️ لا تبنِ هذا الملف مباشرةً — استعمل build_installer.ps1 بجواره.
;    السكربت يبني من **نظيف** ويتحقّق قبل استدعاء ISCC، ويمرّر رقم الإصدار
;    من pubspec.yaml. والبناء من غير نظيف شحن ١٠٠ ميغا من أثر بناء تصحيحٍ
;    عمره شهر (2026-10-12) — `flutter build` لا ينظّف ما لم يبنِه.
;
; ⚠️ احفظ هذا الملف بترميز UTF-8 **مع BOM**. بدونه يقرأ ISCC النصوص العربية
;    بترميز ANSI فتظهر رموزاً مشوّهة في واجهة المثبِّت.
;
; ── القرارات الحاكمة في هذا المثبِّت ─────────────────────────────────────────
;
; ١) نسخة احتياطية **تلقائية** لقاعدة البيانات قبل كل تثبيت أو ترقية.
;    الترقية إلى Schema جديد هي الشيفرة الوحيدة التي تلمس بيانات المالك التي
;    لا تُعوَّض، وقد أفسدت ترقيةٌ قاعدةً حقيقية مرّة (ع-٥٨). والتوصية «خذ نسخة
;    قبل أول تشغيل» تعتمد على تذكّر إنسان — فصارت خطوةً لا تُنسى.
;    وإن فشل النسخ **يتوقّف التثبيت قبل أن يلمس شيئاً** (درس ع-٤٤: رتّب ما
;    يفشل قبل ما لا رجعة فيه).
;
; ٢) التثبيت **لكل مستخدم** لا لكل الجهاز (بلا صلاحيات مدير).
;    قاعدة البيانات تعيش في Documents **الخاصّ بالمستخدم**، فالبرنامج بطبيعته
;    لكل مستخدم. والتثبيت بصلاحية مدير يجعل {userdocs} قد يشير إلى حساب
;    المدير لا حساب من يعمل — فتذهب النسخة الاحتياطية إلى الملف الخطأ أو لا
;    تقع. والفائدة الجانبية: التحديثات لا تطلب كلمة مرور المدير.
;
; ٣) **إلغاء التثبيت لا يمسّ البيانات أبداً.** القاعدة والنسخ والمرفقات خارج
;    مجلد البرنامج عمداً. والحذف الناعم مقدَّس (القانون ٨) — فلا يُعقَل أن
;    يمحو زرُّ «إلغاء التثبيت» الدفاتر كلها.
;
; ٤) مكتبات VC++ مضمَّنة بجوار البرنامج (app-local) — فلا يحتاج الجهاز الهدف
;    إلى تثبيت «Visual C++ Redistributable». وهي التوصية الرسمية لـFlutter
;    عند التوزيع على ويندوز.
; ═══════════════════════════════════════════════════════════════════════════

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppBuild
  #define AppBuild "1"
#endif

#define AppName       "سند"
#define AppNameLatin  "Sanad"
#define AppPublisher  "سند — نظام الخزائن والمحاسبة"
#define AppExeName    "sales_management.exe"

; عنوان نافذة البرنامج كما يكتبه windows/runner/main.cpp حرفياً.
; ⚠️ إن غُيِّر هناك فغيّره هنا — وإلا صار فحص «البرنامج مفتوح» أعمى
;    فيُنسَخ ملف قاعدةٍ يكتب فيها البرنامج لحظتها.
#define AppWindowTitle "Sanad"

; اسم ملف القاعدة كما تفتحه driftDatabase(name: 'sales_management_db').
#define DbFileName    "sales_management_db.sqlite"

#define BuildDir      "..\build\windows\x64\runner\Release"
; ⚠️ مكتبات VC++ تُقرأ من مجلد تجهيز يملؤه build_installer.ps1 — **لا من
;    System32 مباشرةً**. ISCC برنامج ٣٢-بت، فيحوّل ويندوز نظره من System32
;    إلى SysWOW64 حيث النسخ **٣٢-بت** (2026-10-12): فـmsvcp140 وvcruntime140
;    «وُجدتا» بالمعمارية الخطأ، ولم يكشف الأمرَ إلا أن الثالثة لا نسخة ٣٢-بت
;    لها. ولو وُجدت لشُحن برنامج ٦٤-بت بمكتبات ٣٢-بت، فيفشل على كل جهاز بلا
;    VC++ بالخطأ 0xc000007b. والسكربت يتحقّق من معمارية كل ملف قبل النسخ.
#define VcDir         "..\build\vcruntime"

[Setup]
; ⚠️ AppId **ثابت إلى الأبد**. هو ما يجعل المثبِّت الجديد يعرف القديم فيُرقّيه
;    في مكانه. تغييره يُنتج برنامجين مثبَّتين جنباً إلى جنب في «البرامج
;    والميزات» بنسختين من الملفات.
AppId={{900889E4-EA6E-4B55-A11D-C11F1C726963}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}.{#AppBuild}
VersionInfoProductName={#AppNameLatin}
VersionInfoDescription={#AppNameLatin} Setup

; التثبيت لكل مستخدم — راجع القرار ٢ أعلاه
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\{#AppNameLatin}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UsePreviousAppDir=yes

; ٦٤-بت فقط — البناء x64 والمكتبات المضمَّنة x64
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; ويندوز ١٠ فما فوق
MinVersion=10.0

OutputDir=..\dist
OutputBaseFilename=Sanad-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName} {#AppVersion}

Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; إغلاق ما يقفل الملفات عبر Restart Manager — خطّ دفاعٍ ثانٍ فقط.
; الخطّ الأول فحصٌ صريح لنافذة البرنامج في [Code] أدناه، لأن النسخ الاحتياطي
; يجب أن يقع والبرنامج مغلق **يقيناً** لا «على الأرجح».
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Tasks]
Name: "desktopicon"; Description: "إنشاء اختصار على سطح المكتب"; GroupDescription: "اختصارات إضافية:"

[InstallDelete]
; ⚠️ مجلد data يُمحى قبل كل تثبيت ويُكتَب من جديد.
;    المثبِّت لا يحذف وحده ما لم يعد في النسخة الجديدة — فيبقى ملفٌ من نسخة
;    قديمة بجوار الجديدة يُحمَّل أو يُربك. وهذا بعينه ما وقع في بناء الإصدار
;    (kernel_blob.bin بـ١٠٠ ميغا من بناءٍ عمره شهر — 2026-10-12).
;    data لا يحوي إلا ما يُبنى (app.so · الأصول · الخطوط) — لا بيانات مستخدم.
Type: filesandordirs; Name: "{app}\data"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; مكتبات VC++ — راجع القرار ٤ أعلاه
Source: "{#VcDir}\msvcp140.dll";      DestDir: "{app}"; Flags: ignoreversion
Source: "{#VcDir}\vcruntime140.dll";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#VcDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
; دليلا المالك
Source: "..\docs\07-FIELD-TEST.md"; DestDir: "{app}"; DestName: "دليل-الاختبار.md"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\مجلد النسخ الاحتياطية التلقائية"; Filename: "{userdocs}\Sanad-Backups"
Name: "{group}\دليل الاختبار"; Filename: "{app}\دليل-الاختبار.md"
Name: "{group}\إلغاء تثبيت {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "تشغيل {#AppName} الآن"; Flags: nowait postinstall skipifsilent

[Code]
// ─────────────────────────────────────────────────────────────────────────
// هل البرنامج مفتوح؟
//
// يُبحث عن نافذته بعنوانها. والسؤال يُطرح **ثلاث مرّات**: عند بدء المثبِّت،
// وقبل النسخ الاحتياطي مباشرةً (فقد يفتحه المالك أثناء المعالج)، وعند إلغاء
// التثبيت.
// ─────────────────────────────────────────────────────────────────────────
function IsAppRunning(): Boolean;
begin
  Result := FindWindowByWindowName('{#AppWindowTitle}') <> 0;
  // يُسجَّل في كل مرّة — فإن عمي الفحص يوماً ظهر ذلك في سجل المثبِّت (/LOG)
  Log('IsAppRunning: ' + IntToStr(Ord(Result)));
end;

// يطلب إغلاق البرنامج حتى يُغلَق أو يُلغي المستخدم. يُعيد False عند الإلغاء.
function WaitForAppClosed(): Boolean;
begin
  Result := True;
  while IsAppRunning() do
  begin
    // ⚠️ SuppressibleMsgBox لا MsgBox: الثانية **لا تُكتَم** بـ/SUPPRESSMSGBOXES،
    //    فالتثبيت الصامت غير المراقَب ينتظر إلى الأبد إنساناً لا وجود له
    //    (ثُبِّت بسجل المثبِّت 2026-10-12). والأولى تُجيب IDCANCEL عند الكتم
    //    فيخرج المثبِّت نظيفاً بلا أن يلمس شيئاً.
    if SuppressibleMsgBox('برنامج سند مفتوح الآن.' + #13#10#13#10 +
              'أغلقه أولاً ثم اضغط «إعادة المحاولة».' + #13#10 +
              'لا يمكن نسخ قاعدة البيانات احتياطياً أو تحديث البرنامج وهو يكتب فيها.',
              mbError, MB_RETRYCANCEL, IDCANCEL) = IDCANCEL then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := WaitForAppClosed();
end;

function InitializeUninstall(): Boolean;
begin
  Result := WaitForAppClosed();
end;

// ─────────────────────────────────────────────────────────────────────────
// النسخة الاحتياطية التلقائية — قبل أن يلمس المثبِّت أي ملف
//
// تنسخ الملفات الثلاثة **معاً**: القاعدة و-wal و-shm. فـ-wal يحمل أحدث ما
// كُتب قبل دمجه في الملف الأصل (راجع ع-٤٤)، ونسخُ القاعدة وحدها قد يُسقط
// آخر ما أدخله المالك. والثلاثة متّسقة لأن البرنامج مغلق يقيناً.
//
// تُعيد نصّاً فارغاً عند النجاح (أو حين لا قاعدة أصلاً — تثبيت أول)،
// ورسالة خطأ عند الفشل.
// ─────────────────────────────────────────────────────────────────────────
function BackupDatabase(): String;
var
  Docs, Src, DestDir, Stamp, Sfx: String;
  I: Integer;
begin
  Result := '';
  Docs := ExpandConstant('{userdocs}');
  Src := Docs + '\{#DbFileName}';

  // تثبيت أول على هذا الحساب — لا شيء يُنسَخ
  if not FileExists(Src) then
    Exit;

  Stamp := GetDateTimeString('yyyy-mm-dd_hh-nn-ss', '-', '-');
  DestDir := Docs + '\Sanad-Backups\قبل-تثبيت-{#AppVersion}_' + Stamp;

  if not ForceDirectories(DestDir) then
  begin
    Result := 'تعذّر إنشاء مجلد النسخة الاحتياطية:' + #13#10 + DestDir;
    Exit;
  end;

  for I := 0 to 2 do
  begin
    case I of
      0: Sfx := '';
      1: Sfx := '-wal';
      2: Sfx := '-shm';
    end;
    // -wal و-shm قد لا يوجدان (أُغلق البرنامج بنظافة فدُمجا) — وهذا سليم
    if FileExists(Src + Sfx) then
      if not FileCopy(Src + Sfx, DestDir + '\{#DbFileName}' + Sfx, False) then
      begin
        Result := 'تعذّر نسخ ملف قاعدة البيانات:' + #13#10 + Src + Sfx;
        Exit;
      end;
  end;

  Log('Database backed up to: ' + DestDir);
end;

// يُستدعى في صفحة «التحضير للتثبيت» — **قبل** نسخ أي ملف.
// إعادة نصّ غير فارغ توقف التثبيت عند هذه الصفحة بلا أن يُلمَس شيء.
function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  // ربما فُتح البرنامج أثناء المعالج — اسأل ثانيةً قبل النسخ
  if not WaitForAppClosed() then
  begin
    Result := 'أُلغي التثبيت: برنامج سند ما زال مفتوحاً.';
    Exit;
  end;

  Result := BackupDatabase();
  if Result <> '' then
    Result := Result + #13#10#13#10 +
              'أُوقف التثبيت ولم يُلمَس أي ملف — بياناتك كما هي.';
end;

// بعد إلغاء التثبيت: قُل للمالك بوضوح أين بقيت بياناته.
// الصمت هنا يجعله يظنّ أنها حُذفت — أو يظنّ أنه «نظّف» الجهاز وهي باقية.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and not UninstallSilent() then
    MsgBox('أُزيل البرنامج.' + #13#10#13#10 +
           'بياناتك لم تُمَسّ وما زالت في:' + #13#10 +
           ExpandConstant('{userdocs}') + '\{#DbFileName}' + #13#10#13#10 +
           'والنسخ الاحتياطية التلقائية في:' + #13#10 +
           ExpandConstant('{userdocs}') + '\Sanad-Backups' + #13#10#13#10 +
           'إعادة تثبيت سند تُعيدها كما كانت.',
           mbInformation, MB_OK);
end;
