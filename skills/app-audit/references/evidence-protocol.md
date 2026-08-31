# Evidence protocol для app-audit

## Типы доказательств

Каждая finding должна иметь ровно один основной тип, confidence (`high` / `medium` / `low`) и ссылку на источник.

| Тип | Значение | Формат |
| --- | --- | --- |
| `OBSERVED` | реально произошло в видео или живом прогоне | `VIDEO 03:00–03:55`, `SHOT 07-result.png` |
| `CODE-BACKED` | поведение или риск следует из кода, runtime не подтверждён | `CODE Features/Scan.swift:344` |
| `MEASURED` | число пересчитано или замерено | raw values + формула + единицы |
| `EXTERNAL` | App Store, review, конкурент или рыночный источник | URL + storefront + currency + capture date |
| `COMMENT` | мнение владельца, разработчика или пользователя | comment id + timecode; не факт |
| `INFERENCE` | вероятный вывод из нескольких источников | supporting evidence + явная гипотеза |
| `NOT COVERED` | проверить не удалось | причина + что нужно для проверки |

Формат finding:

```text
[P1][OBSERVED][high] Пользователь ждёт результат 55 секунд без прогресса
Evidence: VIDEO 04:12–05:07; SHOT 18-analyzing.png
Impact: trust/activation; связь с paid conversion — INFERENCE, baseline отсутствует
Fix: ...
Acceptance: ...
Size: M
```

## Developer comments

1. Сначала blind pass видео без чтения comments.
2. Затем сопоставить каждый comment с evidence.
3. В отчёте дать статус: `confirmed`, `contradicted`, `still unknown`.
4. Comment не повышает severity без подтверждения.

## Вопросы и assumptions

- Максимум 5 material questions за intake.
- Blocking только отсутствие идентифицируемого приложения или доступа к ключевым входам.
- Всё остальное не тормозит работу: записать assumption, confidence и влияние неизвестности.
- Отсутствие baseline воронки запрещает говорить «повысит conversion на X%»; разрешена гипотеза механизма и план измерения.

## Что чем нельзя доказывать

- Screenshot не доказывает плавность.
- Видео подтверждает latency/visible hitch, но не CPU, FPS или memory без trace.
- Code smell не называется живым багом без runtime evidence.
- Один review не доказывает частоту и причинность.
- Developer comment не является пользовательским исследованием.
- App Store rating/count без storefront/date не воспроизводим.

## Цены и рынок

- Пересчитать weekly×52, monthly×12, annual/day, trial terms и savings labels.
- Для market valuation проверить: exact item, edition/pressing, condition, источник, sold vs listing, currency и дату.
- Эквивалентность не доказана → finding про trust/provenance gap, а не «ошибка в N раз».

## WCAG

Для полупрозрачного текста сначала alpha composite `c = α·text + (1−α)·bg`, затем linear RGB, relative luminance и ratio `(Llight+0.05)/(Ldark+0.05)`. В evidence указать text, background, alpha, ratio и threshold. AA: 4.5:1 обычный текст, 3:1 крупный (≥18pt или ≥14pt bold).

## Единицы

- iOS: `pt`;
- Android/RN layout: `dp`, текст `sp`;
- web: `px`.
