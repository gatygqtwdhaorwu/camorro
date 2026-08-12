#!/usr/bin/env bash
# ============================================================
#  SwarmAttack Framework — مُثبِّت متعدد المنصات (Termux + Linux)
#  يكتشف البيئة تلقائياً ويثبّت المتطلبات بالطريقة الصحيحة لها
# ============================================================
set -euo pipefail

cd "$(dirname "$0")"

if [ -n "${PREFIX:-}" ] && echo "$PREFIX" | grep -q "com.termux"; then
    echo "[*] البيئة المكتشفة: Termux (أندرويد)"

    # --- تحديث الحزم ---
    pkg update -y || true
    pkg upgrade -y || true

    # --- أدوات البناء (مطلوبة فقط لو اضطر pip للبناء — نادراً بعد الخطوة التالية) ---
    pkg install -y clang binutils pkg-config libcurl openssl rust libffi zlib cmake ninja || true

    # --- الحزم الجاهزة من مستودع Termux (الخطوة الحاسمة: بلا بناء من المصدر) ---
    # ملاحظة: إن قال pkg إن إحداها غير موجودة، احذفها من القائمة فقط —
    #        pip سيتكفل بها إن كانت بايثون خالصاً أو لها wheel جاهز.
    pkg install -y python-cryptography python-cffi python-pyyaml python-rich python-aiohttp || true

    # --- لا نستخدم .venv على Termux أبداً (عزل الحزم يقوم به pkg بنفسه) ---
    pip install --upgrade pip || true

    echo "[*] تثبيت المتطلبات عبر pip (بدون عزل البناء)..."
    pip install --no-build-isolation -r requirements.txt \
        || pip install -r requirements.txt

    echo "[*] اكتمل التثبيت. جارٍ تشغيل الاختبار الذاتي..."
    python swarm.py --self-test

else
    echo "[*] البيئة المكتشفة: Linux (سطح مكتب / خادم)"

    # --- أدوات البناء حسب مدير الحزم ---
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y build-essential pkg-config python3-dev python3-venv \
            libssl-dev libffi-dev libcurl4-openssl-dev rustc cargo
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y pkgconf-pkg-config python3-devel openssl-devel libffi-devel \
            libcurl-devel rust cargo
    else
        echo "[!] مدير حزم غير مدعوم (apt/dnf فقط). ثبّت الأدوات يدوياً ثم أعد التشغيل."
        exit 1
    fi

    # --- بيئة افتراضية معزولة (على Linux فقط) ---
    python3 -m venv .venv
    # shellcheck disable=SC1091
    source .venv/bin/activate
    pip install --upgrade pip

    echo "[*] تثبيت المتطلبات..."
    pip install --no-build-isolation -r requirements.txt \
        || pip install -r requirements.txt

    echo "[*] اكتمل التثبيت. جارٍ تشغيل الاختبار الذاتي..."
    python swarm.py --self-test
fi
