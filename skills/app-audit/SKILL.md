---
name: app-audit
description: Запускать когда нужно глубокое ревью мобильного приложения команды — «прогони прилу», «аудит приложения», «дизайн-ревью прилы», «проверь как юзер», «почему приложение выглядит дёшево», «продуктовый анализ приложения». Полный дизайн-, продуктовый и код-аудит по исходникам, полному видео с реального устройства, комментариям разработчика и публичному рынку. Результат — доказательный отчёт A–F, top-10 и передача исправлений тремя волнами.
---

# App Audit — глубокий аудит мобильного продукта

Это единый источник методологии. Launcher-промпты не должны пересказывать фазы своими версиями: они передают входы и требуют выполнить этот skill и references.

Обязательные references, читать полностью до действий:

- `references/evidence-protocol.md` — типы доказательств, вопросы и ограничения выводов;
- `references/live-run-ios.md` — video-first runtime evidence и simulator fallback;
- `references/directions.md` — отдельные проходы и промпты профильным исполнителям;
- `references/report-template.md` — структура отчёта и финальная верификация.

Эталон: `products/vinyl/research/vinyl-appraiser-audit-2026-07-14.md`.

## Железные правила

1. **Код + живые экраны обязательны для полного аудита.** Основной runtime-источник — непрерывное видео с реального устройства. Нет видео и безопасного simulator run — код-аудит продолжается, но результат помечается неполным.
2. **Видео не требует повторной сборки.** Сборка чужого проекта — опциональный диагностический шаг, только когда нужна отсутствующая проверка. Ограничить 20 минутами; failure не останавливает code/video audit.
3. **Каждое направление — отдельный проход.** Product/onboarding, monetization, visual/a11y, code/reliability, performance и competitors не смешивать.
4. **Blind pass до комментариев.** Сначала посмотреть видео и записать собственные наблюдения, затем прочитать developer comments и проверить их.
5. **Факт, риск и мнение не смешивать.** Каждая finding получает тип из evidence-protocol, confidence и воспроизводимое доказательство.
6. **Ключевые цифры пересчитать самостоятельно.** Минимум: weekly×52, monthly×12, WCAG, screenshot count. Рыночную оценку сравнивать только при доказанной эквивалентности.
7. **Исходники приложения не менять.** Не commit/push, не делать покупки, не создавать production-данные намеренно.

## Шаг 0 — intake

Получить или вывести из доступных данных:

- продукт, target user, JTBD и главное действие;
- repo/path, branch/commit и stack;
- полное видео, device/OS и app version/build;
- monetization, storefront/currency и основные конкуренты;
- baseline воронки с периодом и выборкой, если доступен: install → onboarding complete → paywall view → trial → paid; activation/aha и ключевые drop-off;
- developer comments/known issues с timecode;
- ограничения, feature flags, тестовые аккаунты и состояния, которые нельзя трогать;
- что болит владельцу (конверсия, визуал, плавность, доверие) и глубина: полный A–F (default) или одно направление.

Частичный аудит одного направления = фазы 1, 2, его фаза, 9, 10; в отчёте явно пометить частичность и не оценивать оси вне скоупа.

Если repo slug неизвестен, не угадывать. Для gitolite компании:

```bash
ssh <git-user>@<git-host> ls <repo-path>/
git clone <git-user>@<git-host>:<repo-path>/<slug>.git <scratchpad>/<app>
```

Slug может не совпадать с продуктом: Vinyl Appraiser лежал в `ios-vinyl-analysis`. Клон делать во временную папку вне `~/Claude`.

### Вопросы

Задать максимум 5 вопросов, только если ответ меняет scope, severity или рекомендацию. Для каждого указать зависимый вывод.

- **Blocking:** невозможно определить приложение или открыть код/видео — остановиться.
- **Non-blocking:** неизвестна персона, эксперимент, baseline или источник цены — продолжить с явным assumption и вынести вопрос в отчёт.
- Не спрашивать то, что можно достать из кода, видео, brief или listing.

## Определение стека и границы применимости

- `package.json` + `app.json`/`app.config.*` → React Native / Expo;
- `*.xcworkspace` + `Podfile` → нативный iOS с CocoaPods;
- доля `import SwiftUI`/`import UIKit` → SwiftUI, UIKit или гибрид.

Метод полностью обкатан только на iOS/SwiftUI. Product, monetization, visual, competitors и evidence-протокол переносимы; RN/Expo, UIKit и Android требуют соответствующих runtime/performance skills и пометки **«метод на этом стеке не валидирован полностью»**. Не выдавать Swift-метрики за RN/Android-аудит.

## Фазы

| # | Фаза | Исполнитель | Глубина |
| --- | --- | --- | --- |
| 1 | Разведка: архитектура, экраны, навигация, флоу, analytics map | основная сессия | код |
| 2 | Runtime evidence: blind video pass, frames/timecodes, comments comparison | основная сессия | `live-run-ios.md` |
| 3 | Product/UX/onboarding: first/repeat journey, aha, recovery, lifecycle | основная сессия | `onboarding` |
| 4 | Monetization: placements, plans, triggers, trust/refund risk | отдельный проход | `paywalls` |
| 5 | Visual/a11y: hierarchy, WCAG, targets, states, system discipline | основная сессия | `mobile-app-design` |
| 6 | Code/reliability/data/analytics/privacy + design consistency metrics | отдельный проход | `directions.md` |
| 7 | Performance | отдельный проход | SwiftUI: `swiftui-performance-audit`; RN: `react-native-best-practices` |
| 8 | Наш listing, reviews и 4–6 конкурентов | отдельный проход | AppStoreSpy или public App Store |
| 9 | Синтез отчёта и передача тремя волнами | основная сессия | `report-template.md` |
| 10 | Audit-the-audit: проверка доказательств, цифр и файлов | основная сессия | checklist report-template |

Профильный skill читать полностью перед соответствующей фазой. Его Initial Assessment не повторять, если ответы уже есть; material gaps обрабатываются правилами вопросов выше.

## Параллельность

Если среда поддерживает независимых субагентов, фазы 4, 6, 7 и 8 выполнять отдельными исполнителями; 8 можно стартовать вместе с разведкой, 4 — после появления paywall frames, 6/7 — после code recon. Фазы 3 и 5 держать у автора синтеза. Готовые задания — в `directions.md`.

Если субагенты недоступны или запрещены, выполнить те же направления последовательно, сохраняя raw findings после каждого. Изоляция проходов важнее параллельности.

## Runtime и сборка

- Видео с реального устройства — default: реальные данные, системные диалоги, итоговая ценность и настоящие ожидания.
- Зафиксировать video app version/build и audited commit. Если соответствие не доказано — limitation, не повод отменять аудит.
- Simulator/build — только чтобы добрать критичный отсутствующий state, воспроизвести code-backed риск или получить trace. Timebox 20 минут.
- До simulator launch учесть Adjust/Adapty/Firebase: отключить сеть либо записать device id и время для фильтрации.

## Выход

- `product-research/<slug>-audit-<YYYY-MM-DD>.md`;
- `product-research/<slug>-audit-shots/` с уникальными PNG и timecodes;
- raw findings каждого отдельного прохода;
- verdict /10, оси A–F, top-10 по impact×ease, quick wins, «что не ломать», «как навести красоту» и передача разработчику тремя волнами;
- comments: confirmed / contradicted / still unknown;
- assumptions, not covered и next measurement plan.

Не выдумывать десять проблем: если доказанных находок меньше, честно дать меньше.

## После исправлений

Не повторять весь аудит автоматически. Запросить новый commit и новое видео затронутых флоу, затем провести delta-приёмку:

1. проверить acceptance criteria только исправленных P1/P2;
2. проверить соседние состояния на регрессии;
3. сравнить before/after timecodes, screenshots и метрики;
4. обновить статусы finding: fixed / partial / not fixed / regressed;
5. полный повторный A–F запускать только после структурной волны или крупного redesign.

## Красные флаги

- «Кода достаточно» — нет, runtime claims требуют видео/прогона: на Vinyl только живые экраны дали текст чужого продукта на главном экране, три разных имени приложения и завышение оценки ~5×.
- «Видео есть, поэтому version/commit не важны» — несоответствие нужно явно зафиксировать.
- «Соберу обязательно для надёжности» — сборка опциональна и timeboxed.
- «Я и так знаю UX, профильный skill не нужен» — без `paywalls` не заметили дефолт-план в 6.5× дороже годового.
- «Комментарий разработчика подтверждает баг» — это COMMENT до проверки.
- «Отзывы доказывают частоту» — это сигналы без denominator.
- «Ось F потом» — отзывы на наш собственный листинг живут именно там: на Vinyl нашлась живая 1★ на баг распознавания.
- «Модель ошиблась в N раз» без exact item/pressing/condition/source/sold-vs-listing/currency/date — допустим только вывод trust/provenance gap. На Vinyl «$176.93 при Discogs median ~$35» стало находкой «завышение ~5×» только после сверки той же пластинки.
- «Влияние на conversion очевидно» без baseline/эксперимента — это гипотеза, а не measured impact.
- «Сделаю всё одним проходом» — потеря глубины.
- «Отчёт готов без проверки» — фаза 10 обязательна: в первом Vinyl-отчёте разъехались счётчик скринов и порядок секций.
