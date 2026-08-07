// ─────────────────────────────────────────────────────────────────
// خدمة عامل الخلفية لعزل الأصول (COI Service Worker)
// ─────────────────────────────────────────────────────────────────
// الغرض: إضافة ترويسات COOP و COEP تلقائياً لكل الاستجابات
// هذا ضروري لتفعيل SharedArrayBuffer و OPFS في المتصفح
// بدون هذه الترويسات، Drift يتراجع لقاعدة بيانات مؤقتة في الذاكرة
// ─────────────────────────────────────────────────────────────────
//
// المصدر الأصلي: https://github.com/nicolo-ribaudo/coi-serviceworker (MIT)
// تم تعديله ليتوافق مع متطلبات مشروع Sanad App
// ─────────────────────────────────────────────────────────────────

/*! coi-serviceworker v0.1.7 - Guido Zuidhof and nicolo-ribaudo, MIT License */

// ─── ثوابت التكوين ───────────────────────────────────────────────
// هل نسمح بتحميل الـ Service Worker عبر window.coi فقط؟
const GLOBAL_COI = typeof globalThis.coi !== "undefined" ? globalThis.coi : {};

// هل نُظهر رسائل التصحيح في الكونسول؟
const COI_QUIET = GLOBAL_COI.quiet || false;

// ─── منطق الـ Service Worker ─────────────────────────────────────
if (typeof window === "undefined") {
  // ═══════════════════════════════════════════════════════════════
  // نحن داخل سياق الـ Service Worker
  // نعترض كل الطلبات ونضيف الترويسات المطلوبة للاستجابات
  // ═══════════════════════════════════════════════════════════════

  self.addEventListener("install", () => {
    // تفعيل فوري دون انتظار إغلاق التبويبات القديمة
    self.skipWaiting();
  });

  self.addEventListener("activate", (event) => {
    // التحكم بجميع العملاء (التبويبات) فوراً
    event.waitUntil(self.clients.claim());
  });

  self.addEventListener("fetch", function (event) {
    // ─── اعتراض كل طلب وإضافة ترويسات العزل ───────────────────
    const request = event.request;

    // نتجاهل الطلبات غير GET (POST, PUT, DELETE الخ)
    if (request.mode === "navigate" || (request.mode === "no-cors" && request.destination === "script")) {
      event.respondWith(
        fetch(request)
          .then((response) => {
            // لا نستطيع تعديل الاستجابة مباشرة — ننشئ نسخة جديدة
            const newHeaders = new Headers(response.headers);

            // ── الترويسة الأولى: Cross-Origin-Opener-Policy ────
            // تمنع النوافذ الخارجية من الوصول لهذا السياق
            newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

            // ── الترويسة الثانية: Cross-Origin-Embedder-Policy ──
            // تمنع تحميل موارد خارجية بدون CORS
            // نستخدم credentialless بدلاً من require-corp لتقليل القيود
            newHeaders.set(
              "Cross-Origin-Embedder-Policy",
              "credentialless"
            );

            return new Response(response.body, {
              status: response.status,
              statusText: response.statusText,
              headers: newHeaders,
            });
          })
          .catch((e) => {
            // في حال فشل الطلب — نعيد الخطأ كما هو
            console.error("COI Service Worker fetch error:", e);
            return new Response("Service Worker fetch failed", { status: 500 });
          })
      );
    }
  });

} else {
  // ═══════════════════════════════════════════════════════════════
  // نحن داخل سياق النافذة (Window Context)
  // نقوم بتسجيل الـ Service Worker
  // ═══════════════════════════════════════════════════════════════

  (() => {
    // ─── فحص: هل الصفحة معزولة أصلاً؟ ─────────────────────────
    // إذا كانت الترويسات موجودة من الخادم، لا حاجة للـ Service Worker
    const isAlreadyIsolated = window.crossOriginIsolated;

    if (isAlreadyIsolated) {
      if (!COI_QUIET) {
        console.log("🔒 COI: الصفحة معزولة أصلاً — OPFS متاح بدون Service Worker");
      }
      return;
    }

    // ─── فحص: هل المتصفح يدعم Service Workers؟ ─────────────────
    if (!window.isSecureContext) {
      if (!COI_QUIET) {
        console.warn("⚠️ COI: يجب تشغيل التطبيق عبر HTTPS أو localhost");
      }
      return;
    }

    if (!("serviceWorker" in navigator)) {
      if (!COI_QUIET) {
        console.warn("⚠️ COI: المتصفح لا يدعم Service Workers");
      }
      return;
    }

    // ─── تسجيل الـ Service Worker ──────────────────────────────
    navigator.serviceWorker
      .register(new URL("coi-serviceworker.js", window.location.href).href)
      .then(
        (registration) => {
          if (!COI_QUIET) {
            console.log("✅ COI Service Worker مسجل بنجاح");
          }

          // ─── إعادة تحميل الصفحة بعد التفعيل ─────────────────
          // عند التسجيل لأول مرة، نحتاج إعادة تحميل
          // لتطبيق الترويسات على الصفحة الحالية
          registration.addEventListener("updatefound", () => {
            const worker = registration.installing;
            if (!worker) return;

            worker.addEventListener("statechange", () => {
              if (worker.state === "activated") {
                if (!COI_QUIET) {
                  console.log("🔄 COI: إعادة تحميل الصفحة لتفعيل العزل...");
                }
                window.location.reload();
              }
            });
          });
        },
        (err) => {
          console.error("❌ COI: فشل تسجيل Service Worker:", err);
        }
      );
  })();
}
