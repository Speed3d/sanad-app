# -*- coding: utf-8 -*-
# ═══════════════════════════════════════════════════════════════════════════
# توليد أيقونة سند لويندوز من الشعار — windows/runner/resources/app_icon.ico
# ═══════════════════════════════════════════════════════════════════════════
#
# الاستعمال (من جذر المشروع، ويحتاج Pillow — أداة تطوير لا تبعية للبرنامج):
#     python installer/make_icon.py
# ثم أعد بناء المثبِّت: installer/build_installer.ps1
#
# المصدر: docs/لوكو سند.png — شعار المالك (2026-10-14)
#
# ═══ لماذا ليست الصورة نفسها مصغَّرة؟ (قرار المالك — الخيار «د») ═══
#   الشعار **عريض** (نحو ١٫٨ : ١) والأيقونة مربّعة، فلا يشغل إلا أقلّ من نصف
#   ارتفاعها. وعُرضت على المالك أربعة خيارات بأحجامها الحقيقية فاختار:
#
#   • ٤٨ بكسل فأكبر (سطح المكتب · المستكشف): الشعار **كاملاً** على مربّع أبيض
#     مستدير الأطراف
#   • أصغر من ٤٨ (شريط المهام · قائمة ابدأ · عنوان النافذة): **رمز الورقة
#     وحده** من الشعار نفسه، على المربّع الأبيض
#
#   ولماذا المربّع الأبيض؟ لأن حروف «سند» **كحلية**، وشريط مهام ويندوز ١١
#   داكنٌ افتراضاً — فبلا خلفية تكاد تختفي. ولماذا الرمز في الصغير؟ لأن
#   الشعار الكامل في ١٦–٣٢ بكسل شريطٌ رفيع لا يُقرأ، وتلك بالذات المقاسات
#   التي يراها المالك أكثر من غيرها.
# ═══════════════════════════════════════════════════════════════════════════

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'docs' / 'لوكو سند.png'
OUT_ICO = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'

# المقاسات التي يطلبها ويندوز في مواضعه المختلفة (١٠٠٪ إلى ٢٠٠٪ تكبير)
SIZES = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]

# من هذا المقاس فأكبر يُستعمل الشعار كاملاً، ودونه الرمز وحده
FULL_LOGO_MIN = 48

# منطقة رمز الورقة داخل الشعار الأصلي (بكسلات المصدر ١٠٩٨×٦٢٣) —
# ⚠️ إن تغيّر الشعار فراجع هذه الإحداثيات، وإلا قُصّ جزءٌ خاطئ منه
SYMBOL_BOX = (700, 66, 1072, 548)

WHITE = (255, 255, 255, 255)


def _trim(im: Image.Image) -> Image.Image:
    """يقصّ الهوامش الشفّافة."""
    return im.crop(im.getchannel('A').getbbox())


def _tile(content: Image.Image, padding: float) -> Image.Image:
    """يضع الصورة في وسط مربّع أبيض مستدير الأطراف — ١٠٢٤ بكسل."""
    w, h = content.size
    side = int(max(w, h) * padding)
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    mask = Image.new('L', (side, side), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, side - 1, side - 1], radius=int(side * 0.22), fill=255)
    canvas.paste(Image.new('RGBA', (side, side), WHITE), (0, 0), mask)
    canvas.paste(content, ((side - w) // 2, (side - h) // 2), content)
    return canvas.resize((1024, 1024), Image.LANCZOS)


def main() -> None:
    # طرفية ويندوز ترمّز بـ cp1252 افتراضاً فتفشل الطباعة العربية — بعد أن
    # تكون الأيقونة قد حُفظت، فيبدو السكربت فاشلاً وهو ناجح
    sys.stdout.reconfigure(encoding='utf-8')
    src = Image.open(SOURCE).convert('RGBA')
    full = _tile(_trim(src), padding=1.18)
    symbol = _tile(_trim(src.crop(SYMBOL_BOX)), padding=1.30)

    frames = {
        s: (full if s >= FULL_LOGO_MIN else symbol).resize((s, s), Image.LANCZOS)
        for s in SIZES
    }
    largest = frames[max(SIZES)]
    others = [frames[s] for s in SIZES if s != max(SIZES)]
    largest.save(OUT_ICO, format='ICO', sizes=[(s, s) for s in SIZES],
                 append_images=others)
    print(f'✓ {OUT_ICO.relative_to(ROOT)} — {len(SIZES)} مقاسات')


if __name__ == '__main__':
    main()
