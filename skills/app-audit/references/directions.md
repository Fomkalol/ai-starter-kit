# Отдельные проходы app-audit

Подставить `<ROOT>`, `<SHOTS>`, `<VIDEO>` и `<CONTEXT>`. Пути из Vinyl не копировать: сначала найти реальные modules/screens аудируемого repo.

Каждый проход возвращает raw findings, а не готовый общий отчёт. Обязательный формат каждой finding:

```text
[P1/P2/P3][OBSERVED/CODE-BACKED/MEASURED/EXTERNAL/COMMENT/INFERENCE][confidence]
Суть · evidence (timecode/shot/file:line/URL) · impact · конкретный fix · acceptance · S/M/L
```

Полный протокол — `evidence-protocol.md`. Initial Assessment профильного skill не повторять, если ответы есть в code/video/context. Material gap вернуть автору как вопрос; остальные неизвестные пометить assumption/not covered.

## Порядок и параллельность

- Competitors (8) можно запускать параллельно с recon.
- Monetization (4) — после paywall frames; code/reliability (6) и performance (7) — после recon.
- В Claude с доступными субагентами 4/6/7/8 выполнять параллельно отдельными исполнителями.
- В Codex или среде без субагентов выполнить последовательно, но не смешивать findings между проходами.
- Product/onboarding (3) и visual/a11y (5) держать у автора итогового синтеза.

## Фаза 3 — Product / onboarding

Использовать `onboarding`.

> По `<VIDEO>` и `<SHOTS>` построй first-session и repeat-session journey. Определи target JTBD, aha/activation и посчитай screens, decisions и taps до ценности. Проверь dead steps, premature asks, permissions/ATT/review timing, использование quiz answers, empty/error recovery, background/relaunch/push contradictions. Сопоставь с baseline воронки из `<CONTEXT>`; если baseline нет, conversion impact маркируй INFERENCE и предложи событие/эксперимент для измерения. Верни raw findings по evidence-протоколу и отдельно «что хорошо, не ломать».

## Фаза 4 — Monetization

Использовать `paywalls`; при реальной необходимости `pricing`, `offers`, `cro`.

> Разбери все paywall placements/variants/triggers в `<ROOT>` и frames в `<SHOTS>`. Проверь offer/value proof за 3 секунды, default plan, trial, close/cooldown/post-dismiss, restore/legal, entitlement recovery и fallback/demo content. Сам пересчитай weekly×52, monthly×12, annual/day, savings labels. Раздели conversion hypothesis и refund/trust risk. Сопоставь с paywall view→trial→paid baseline из `<CONTEXT>`; без данных не обещай uplift. Верни raw findings и максимум 5 A/B-гипотез: mechanism, primary metric, guardrails, required sample/event.

## Фаза 5 — Visual / accessibility

Использовать `mobile-app-design`; `impeccable` только для финальной полировки подтверждённых проблем.

> По каждому важному экрану в `<SHOTS>` проведи 3-second hierarchy test: typography, spacing, color/accent, icon style, states, safe area, keyboard/sheets. Проверь iOS touch targets 44pt либо Android dp/sp, Dynamic Type, VoiceOver order/labels, Reduce Motion и различимость без цвета. WCAG пересчитай через alpha composite и relative luminance, указав text/bg/alpha/ratio/threshold. Сначала докажи, нужна дисциплина существующей системы или redesign. Не выдумывай размеры и цвета без измерения/HIG/существующих tokens.

## Фаза 6 — Code / consistency / reliability / data / analytics / privacy

> Проведи read-only аудит `<ROOT>`. Сначала определи, есть ли design tokens/components; если нет — это finding, а не «0 нарушений». Дай grep-метрики raw colors/fonts/radii/spacing и handmade component copies с top offender file:line. Затем проверь state ownership, observation fan-out, identity, cancellation, lifecycle, retry/timeout, offline/session recovery и error mapping. Проверь data integrity: stale state, double count, fake/demo data, cache invalidation, migrations. Построй analytics map для install→onboarding→paywall→trial→paid и aha; найди пропуски/дубли/неверные moments, но не отправляй события. По доступному коду проверь secrets, PII logs, tracking permission timing и storage. Security/privacy claims только с evidence. Верни цифры и raw findings, код не меняй.

Для SwiftUI отдельно считать `.font(.system`, raw `Color`/`UIColor`, numeric `cornerRadius`/`padding`/`spacing`, dark variants и копии кнопок. Для RN/Android адаптировать метрики под theme/style system; не применять Swift grep вслепую.

## Фаза 7 — Performance

SwiftUI: `swiftui-performance-audit`; RN: `react-native-best-practices`.

> Проведи code-first performance audit `<ROOT>`. Приоритет: main-thread I/O/decode, image downsampling/cache, list laziness/identity, invalidation storms, timers/repeatForever/asyncAfter cancellation, media lifecycle, layout thrash и тяжёлый body/render. По `<VIDEO>` можно подтвердить latency/visible hitch. CPU/FPS/memory называй только при наличии trace, иначе CODE-BACKED risk. Для server action раздели perceived wait и rendering performance. Верни file:line, mechanism, user-visible impact, узкий fix и способ измерить после исправления.

## Фаза 8 — Competitors / наш listing / reviews

> Найди наш listing и 4–6 реальных конкурентов через AppStoreSpy; если недоступен — public apps.apple.com и публичный web. Для каждого фиксируй app id, прямой URL, storefront, currency и capture date. Собери positioning, rating/count, public price signals, UX strengths и themes written reviews. Клонов с <10 ratings отделяй как шум, если нет особой причины. Один review — сигнал, не частота. Не выдумывай downloads/revenue. Дай 5 выводов: где догнать рынок, где не копировать лидера и где выиграть.

## Для AI-оценки и распознавания

Сверить 1–2 результата с профильным рынком, но прежде доказать эквивалентность: exact item/edition/pressing, condition, sold vs listing, currency и дата. Не доказано совпадение → finding `trust/provenance gap`, а не «модель ошиблась в N раз». Проверить, не выдаётся ли fallback/sample/floor за персональный результат.

## Синтез

- Подозрительно пустой проход перепроверить: частая причина — профильный skill остановился на Initial Assessment.
- Ключевые числа пересчитать автору отчёта, не брать из raw findings на веру.
- Дубликаты findings объединять, сохраняя все evidence links.
- Business impact без baseline/эксперимента обозначать INFERENCE.
- Полные raw findings приложить в конец отчёта, не выбрасывать.
