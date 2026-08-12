"""
compat.py — طبقة التوافق بين Termux (أندرويد) و Linux
============================================================
توفّر:
  - detect_environment(): كشف البيئة الحالية (termux / linux / other)
  - is_termux():          هل نعمل داخل Termux؟
  - platform_hint():      نص وصفي للبيئة الحالية
  - default_max_cells():  أقصى عدد خلايا (Cells) آمن حسب البيئة
  - memory_safe_queue():  حجم طابور الذاكرة الآمن حسب البيئة
  - warn_optional():      تحذير موحّد عند غياب وحدة اختيارية

لماذا هذا الملف؟
  - Termux يعمل بنواة أندرويد (aarch64-linux-android) وليس Linux مكتبياً
  - بعض الحزم المترجمة لا تتوفر فيه عبر pip (cryptography, scapy...)
  - موارد الهاتف (ذاكرة/معالجات) محدودة → يجب خفض الافتراضيات
"""

import os
import sys


def detect_environment() -> str:
    """يكشف البيئة الحالية: 'termux' أو 'linux' أو 'other'."""
    prefix = os.environ.get("PREFIX", "")
    if "com.termux" in prefix:
        return "termux"
    if sys.platform.startswith("linux"):
        return "linux"
    return "other"


def is_termux() -> bool:
    """هل نعمل داخل Termux (أندرويد)؟"""
    return detect_environment() == "termux"


def platform_hint() -> str:
    """نص وصفي للبيئة الحالية (للعرض في الواجهة والسجلات)."""
    if is_termux():
        return "Termux (أندرويد)"
    return "Linux (سطح مكتب / خادم)"


def default_max_cells(configured: int) -> int:
    """
    يحدد أقصى عدد خلايا آمن حسب البيئة:
      - Termux:  حد أقصى 4، ونصف عدد المعالجات على الأكثر (حماية للهاتف)
      - Linux:   حد أقصى 24 (مريح للخوادم وسطح المكتب)
    """
    if configured <= 0:
        return 1
    if is_termux():
        cpu = os.cpu_count() or 2
        return max(1, min(configured, 4, cpu // 2))
    return min(configured, 24)


def memory_safe_queue() -> int:
    """حجم طابور الذاكرة الآمن (1024 على Termux / 4096 على Linux)."""
    return 1024 if is_termux() else 4096


def warn_optional(module: str, termux_pkg: str, linux_pip: str) -> None:
    """تحذير موحّد عند غياب وحدة اختيارية، مع أمر التثبيت الصحيح لكل منصة."""
    if is_termux():
        print(f"[!] الوحدة الاختيارية '{module}' غير متوفرة.\n"
              f"    على Termux ثبّتها: pkg install {termux_pkg}")
    else:
        print(f"[!] الوحدة الاختيارية '{module}' غير متوفرة.\n"
              f"    على Linux ثبّتها: pip install {linux_pip}")
