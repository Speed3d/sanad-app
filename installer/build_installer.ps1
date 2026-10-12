# ═══════════════════════════════════════════════════════════════════════════
# بناء مثبِّت سند لويندوز — من الصفر إلى ملف Setup واحد
# ═══════════════════════════════════════════════════════════════════════════
#
# الاستعمال (من جذر المشروع):
#     powershell -ExecutionPolicy Bypass -File installer\build_installer.ps1
#
# الناتج:  dist\Sanad-Setup-<الإصدار>.exe
#
# ⚠️ احفظ هذا الملف بترميز UTF-8 **مع BOM** — PowerShell 5.1 يقرأ الملف
#    بلا BOM بترميز ANSI فتتشوّه الرسائل العربية.
#
# لماذا سكربت لا أوامر يدوية؟ لأن كل خطوة هنا **درسٌ وقع فعلاً**:
#   ١) المحلّل والاختبارات أولاً — القانون ١. لا تُشحَن نسخةٌ لم تمرّ بهما.
#   ٢) flutter clean قبل البناء — `flutter build` لا ينظّف ما لم يبنِه، فشُحن
#      kernel_blob.bin بـ١٠٠ ميغا من بناء تصحيحٍ عمره شهر (2026-10-12).
#   ٣) حارس بعد البناء يرفض الناتج إن حمل ذلك الأثر — فالتنظيف وحده وعدٌ،
#      والحارس هو ما يحقّقه (ع-٥٤: وعدٌ مكتوب بلا حارس).
#   ٤) رقم الإصدار يُقرأ من pubspec.yaml — مصدرٌ واحد لا نسختان (ع-٥٦: قائمة
#      منسوخة بدل مشتقّة).
# ═══════════════════════════════════════════════════════════════════════════

param(
    # تخطّي المحلّل والاختبارات — للبناء التجريبي **فقط**، لا لنسخة تُسلَّم
    [switch]$SkipChecks
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Step($msg) { Write-Host "`n━━ $msg" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "`n✗ $msg" -ForegroundColor Red; exit 1 }

# يشغّل أمراً خارجياً ويوقف السكربت إن فشل.
# ⚠️ $ErrorActionPreference لا يلتقط فشل البرامج الخارجية في PowerShell 5.1،
#    فبدون فحص $LASTEXITCODE يمضي السكربت بعد اختبارٍ فاشل ويبني نسخةً معطوبة.
function Run($exe, [string[]]$argv, $what) {
    & $exe @argv
    if ($LASTEXITCODE -ne 0) { Fail "$what فشل (رمز الخروج $LASTEXITCODE)" }
}

# ── ١. رقم الإصدار من pubspec.yaml ──────────────────────────────────────────
Step 'قراءة رقم الإصدار من pubspec.yaml'
$line = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)' | Select-Object -First 1
if (-not $line) { Fail 'لم يُعثَر على سطر version بالصيغة 1.2.3+4 في pubspec.yaml' }
$version = $line.Matches[0].Groups[1].Value
$build   = $line.Matches[0].Groups[2].Value
Write-Host "الإصدار $version (البناء $build)"

# ── ٢. أداة Inno Setup ───────────────────────────────────────────────────────
$iscc = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { Fail 'لم يُعثَر على Inno Setup 6 (ISCC.exe)' }

# ── ٣. المحلّل والاختبارات — القانون ١ ──────────────────────────────────────
if ($SkipChecks) {
    Write-Host "`n⚠️  تخطّي الفحوص — لا تسلّم هذه النسخة" -ForegroundColor Yellow
} else {
    Step 'flutter analyze'
    Run 'flutter' @('analyze') 'المحلّل'
    Step 'flutter test'
    Run 'flutter' @('test') 'الاختبارات'
}

# ── ٤. البناء من نظيف ───────────────────────────────────────────────────────
Step 'flutter clean'
Run 'flutter' @('clean') 'التنظيف'
Step 'flutter pub get'
Run 'flutter' @('pub', 'get') 'جلب الحزم'
Step 'flutter build windows --release'
Run 'flutter' @('build', 'windows', '--release') 'بناء الإصدار'

# ── ٥. حارس الناتج ──────────────────────────────────────────────────────────
Step 'فحص ناتج البناء'
$rel = 'build\windows\x64\runner\Release'
$required = @(
    'sales_management.exe', 'flutter_windows.dll', 'sqlite3.dll',
    # بلا pdfium.dll تتعطّل الطباعة كلها
    'pdfium.dll', 'printing_plugin.dll',
    'data\app.so', 'data\icudtl.dat',
    # الخط العريض — عصب إصلاح العربية في PDF (ع-٠٥)
    'data\flutter_assets\assets\fonts\Tajawal-Bold.ttf'
)
foreach ($f in $required) {
    if (-not (Test-Path (Join-Path $rel $f))) { Fail "ملف لازم مفقود من الناتج: $f" }
}
# أثر بناء التصحيح — نسخة الإصدار تستعمل app.so ولا تحتاجه
if (Get-ChildItem $rel -Recurse -Filter 'kernel_blob.bin' -ErrorAction SilentlyContinue) {
    Fail 'الناتج يحمل kernel_blob.bin — أثر بناء تصحيح. لا يُشحَن.'
}
$appSo = Get-Item (Join-Path $rel 'data\app.so')
if ($appSo.LastWriteTime -lt (Get-Date).AddMinutes(-30)) {
    Fail "app.so قديم ($($appSo.LastWriteTime)) — البناء لم يُحدّثه"
}
$sizeMb = [math]::Round(((Get-ChildItem $rel -Recurse | Measure-Object Length -Sum).Sum / 1MB), 1)
Write-Host "✓ الناتج سليم — $sizeMb ميغا"

# ── ٥ب. مكتبات VC++ بمعماريتها الصحيحة ─────────────────────────────────────
# ⚠️ لا يقرأ ISCC من System32 بنفسه: هو برنامج ٣٢-بت فيحوّله ويندوز إلى
#    SysWOW64 ويلتقط النسخ **٣٢-بت** بصمت (2026-10-12). فهنا — في عملية ٦٤-بت
#    — تُنسخ إلى مجلد تجهيز، **ويُفحص رأس PE لكل ملف**: الاسم وحده لا يقول
#    المعمارية، والملفّان الخطآن كانا يحملان الأسماء الصحيحة تماماً.
Step 'تجهيز مكتبات VC++ (x64)'
$sys = if ([Environment]::Is64BitProcess) { 'System32' } else { 'Sysnative' }
$vcOut = 'build\vcruntime'
New-Item -ItemType Directory -Force $vcOut | Out-Null
foreach ($d in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    $src = Join-Path $env:windir "$sys\$d"
    if (-not (Test-Path $src)) { Fail "مكتبة VC++ مفقودة من النظام: $src" }
    Copy-Item $src $vcOut -Force
    $b = [IO.File]::ReadAllBytes((Join-Path $vcOut $d))
    $machine = [BitConverter]::ToUInt16($b, [BitConverter]::ToInt32($b, 0x3C) + 4)
    if ($machine -ne 0x8664) { Fail ("{0} ليست x64 (Machine=0x{1:X4})" -f $d, $machine) }
}
Write-Host '✓ المكتبات الثلاث x64'

# ── ٦. المثبِّت ──────────────────────────────────────────────────────────────
Step 'بناء المثبِّت بـ Inno Setup'
Run $iscc @("/DAppVersion=$version", "/DAppBuild=$build", 'installer\sanad.iss') 'Inno Setup'

$setup = "dist\Sanad-Setup-$version.exe"
if (-not (Test-Path $setup)) { Fail "لم يُنتَج $setup" }
$setupMb = [math]::Round((Get-Item $setup).Length / 1MB, 1)
Write-Host "`n✓ جاهز: $setup ($setupMb ميغا)" -ForegroundColor Green
