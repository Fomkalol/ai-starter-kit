# Шаблон отчёта и приёмка app-audit

Эталон: `products/vinyl/research/vinyl-appraiser-audit-2026-07-14.md`.

Выход:

- `product-research/<slug>-audit-<YYYY-MM-DD>.md`;
- `product-research/<slug>-audit-shots/`;
- при повторной приёмке: `product-research/<slug>-audit-delta-<YYYY-MM-DD>.md`.

## Структура полного отчёта

```markdown
# <App> — дизайн-, продуктовый и код-аудит (<дата>)

## Контекст и метод
Repo/path · branch/commit · stack · video path/duration/device/OS/app version/build · storefront/currency/capture date · метод runtime evidence · build/simulator status, если применялся.

Coverage / not covered / version mismatch / ограничения стека.

## Business baseline
Период, выборка и источник: install → onboarding complete → paywall view → trial → paid; activation/aha; главные drop-off. Нет данных — явно «не предоставлено», все conversion claims ниже = hypotheses.

## Вердикт: N/10
Что сильно и 3–4 главных ограничения. Отдельно: findings, которые дал только runtime evidence.

## Оценки A–F
A первое впечатление · B иерархия/типографика · C цвет/консистентность · D плавность · E UX-флоу · F конкуренты.
Якоря: 3 = ломает/отталкивает; 5 = работает, но дёшево/непоследовательно; 7 = крепко; 9 = эталон ниши. Итог взвешен по деньгам/доверию, не механическое среднее.

## Top-10 по impact × ease
Если доказанных findings меньше десяти — дать меньше, не выдумывать.
Каждая: priority · evidence type · confidence · суть · evidence · user/business impact · конкретный fix · acceptance · S/M/L.

## Карта экранов
Экран · timecode/shot · оценка · главная проблема · состояние.

## Product и onboarding
First/repeat journey · aha · screens/taps/decisions · recovery/lifecycle · связь с baseline или hypothesis.

## Monetization
Placements/variants/triggers · price math · default/trial/dismiss/cooldown · trust/refund risk · до 5 A/B hypotheses с metric и guardrails.

## Competitors и reviews
Наш listing + 4–6 конкурентов · storefront/currency/date/URL · темы отзывов · 5 выводов.

## Visual и accessibility
Hierarchy · type/spacing/color/icon consistency · touch targets · Dynamic Type/VoiceOver/Reduce Motion · WCAG calculations.

## Performance
Observed latency/hitches отдельно от code-backed risks и trace-backed metrics.

## Code, consistency, reliability, data, analytics, privacy
Design-system metrics · state/lifecycle/retry · data integrity · funnel instrumentation · evidence-backed privacy risks.

## Developer comments
Comment id/timecode · confirmed / contradicted / still unknown · evidence.

## Quick wins за день
Только реальные 1-day items, каждый с shot/timecode или file:line и acceptance.

## Что хорошо — не ломать

## Как навести красоту
Сначала ответ: дисциплина существующей системы или redesign. Затем system changes before cosmetics.

## Передача разработчику тремя волнами
Для каждого пункта: evidence · expected outcome · acceptance · dependencies · size.
1. Quick wins — 1 день.
2. Structural — 1–2 недели.
3. Visual system — фоном/после структурного.

## Questions, assumptions и next measurement plan

## Приложение: evidence index
Каждый PNG с описанием и timecode; STORE/CODE/COMMENT sources.

## Raw findings отдельных проходов
```

## Evidence в finding

Использовать типы из `evidence-protocol.md`:

```text
[P1][OBSERVED][high] <finding>
Evidence: VIDEO 03:00–03:55; SHOT 07-result.png
Impact: <measured или явно inference>
Fix: <конкретно>
Acceptance: <проверяемо>
Size: S/M/L
```

Визуальный баг может иметь screenshot без file:line; code claim требует точный file:line. Comment не заменяет evidence.

## «Как навести красоту»

Не начинать с redesign. Проверить:

1. Есть ли tokens/components и нарушаются ли они.
2. Есть ли единый brand accent уже в hero/assets.
3. Можно ли сделать главный value screen эталонным и подтянуть остальные.
4. Нужны ли motion/haptics/skeletons под конкретную подтверждённую проблему.

Если системы нет, предложить минимальную систему. Если система есть, но обходится — дисциплину, а не новую библиотеку.

## Чеклист полного аудита — фаза 10

### Входы и версии

- [ ] Repo, branch и commit указаны.
- [ ] Video path, duration, device/OS и app version/build указаны.
- [ ] Video build ↔ commit подтверждены или mismatch/unknown записан.
- [ ] Storefront, currency и capture date указаны.
- [ ] RN/Android/UIKit limitation указана, если применимо.

### Evidence

- [ ] Blind observations сделаны до developer comments.
- [ ] Каждый top finding имеет type, confidence и screenshot/timecode или file:line.
- [ ] OBSERVED, CODE-BACKED, COMMENT и INFERENCE не смешаны.
- [ ] Comments имеют confirmed/contradicted/still unknown.
- [ ] Performance без trace не содержит claims про FPS/CPU/memory.
- [ ] Review themes не выданы за частоту.
- [ ] Market valuation соблюдает exact-equivalence caveat.

### Числа и файлы

- [ ] PNG count в тексте равен числу файлов.
- [ ] SHA-дубли удалены; каждый PNG описан и связан с timecode.
- [ ] Screens/timecodes действительно соответствуют описанию.
- [ ] weekly×52, monthly×12, daily equivalents и savings пересчитаны.
- [ ] WCAG содержит raw colors/alpha/ratio/threshold.
- [ ] Business baseline имеет period/sample/source либо честно отсутствует.

### Полнота и логика

- [ ] Все оси A–F закрыты.
- [ ] Оценки экранов и общий verdict не противоречат findings.
- [ ] Проходы product, monetization, visual, code/reliability, performance и competitors выполнены отдельно.
- [ ] Top-10 отсортирован по impact×ease; отсутствующие findings не выдуманы.
- [ ] Fix конкретен, acceptance проверяем, размер указан.
- [ ] Quick wins реально укладываются в день.
- [ ] Есть «что хорошо, не ломать».
- [ ] Есть assumptions, not covered и next measurement plan.
- [ ] Raw findings сохранены.

### Безопасность выполнения

- [ ] Build был только по причине из live-run и уложен в timebox либо не выполнялся.
- [ ] Simulator analytics noise предотвращён либо device/time записаны.
- [ ] Исходники приложения не изменены.
- [ ] Commit/push/purchase/external production writes не выполнялись.

Чеклист не просто отметить: найденные расхождения исправить в отчёте до финального ответа.

## Delta-приёмка после исправлений

Не копировать полный отчёт. Использовать новый commit и новое видео затронутых флоу.

```markdown
# <App> — delta-приёмка (<дата>)
Base audit · old/new commit · old/new app version/build · old/new video.

## Итог
Сколько fixed / partial / not fixed / regressed.

## Проверка исправлений
Finding id · прежнее evidence · новое evidence · acceptance · status · комментарий.

## Регрессии соседних состояний

## Before/after
Screenshots, timecodes и доступные funnel/performance metrics.

## Осталось до следующей волны
```

Полный повтор A–F нужен только после структурной волны, крупного redesign или существенного изменения продукта.
