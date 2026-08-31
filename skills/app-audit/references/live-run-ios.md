# Runtime evidence: real-device video first, Simulator fallback

Полный аудит требует живых экранов. По умолчанию использовать непрерывное видео с реального устройства; сборка и Simulator нужны только для конкретного пробела или диагностики.

## A. Видео с реального устройства — основной путь

### Чеклист разработчику

Снять одним непрерывным проходом, не вырезая ожидания. Желательно включить отображение тапов или проговаривать действия.

- Показать App Store listing либо Settings/About с version/build.
- Полностью закрыть приложение и начать с cold launch.
- Для first run: удалить приложение, поставить заново, пройти splash, onboarding и системные разрешения.
- Показать все paywall states: планы, trial, close, restore/legal. Реальную покупку не совершать без отдельного разрешения.
- Выполнить главный happy path на реальных или безопасных синтетических данных до конечной ценности.
- Оставить loading целиком; на статичных экранах задерживаться примерно 2 секунды.
- Прокрутить результат полностью, включая disclosure, sources и links.
- Показать безопасно достижимые error/retry/empty states.
- Открыть все top-level tabs, Settings, account/sync/subscription controls.
- Показать повторный cold launch, background/foreground и push, если они входят в lifecycle.
- Специально проверить длинные списки, переходы и места, которые субъективно тормозят; назвать проблему вслух или дать timecode в brief.

Перед записью убрать PII, токены, email и платёжные данные. Для медицинских, финансовых и детских продуктов использовать синтетические данные.

### Blind pass и comments

1. Сначала просмотреть видео без developer comments и записать timecoded observations.
2. Затем прочитать comments и классифицировать: confirmed / contradicted / still unknown.
3. Проверить duration, resolution, device/OS, app version/build.
4. Сопоставить video build с audited commit. Если нельзя — указать limitation.

### Нарезка

```bash
swift .claude/skills/app-audit/scripts/frames.swift <video> <shots-dir> 0.5
```

- Обзор: 0.5 fps, затем дополнительные кадры на каждом изменении состояния.
- Подозрительный короткий переход: 4–8 fps только на нужном отрезке.
- Сохранить уникальные PNG с последовательными осмысленными именами.
- В evidence index связать каждый файл с timecode и экраном.
- Не читать сотни почти одинаковых кадров; SHA-дубли удалить.
- Полные waits измерять start/end timecode, не по числу кадров.

Видео подтверждает latency и заметный hitch, но не точные FPS/CPU/memory — для этого нужен Instruments/trace.

## B. Нужна ли сборка

**Default: нет.** Видео уже показывает production behavior, а пересборка чужого Xcode-проекта часто дорога и не даёт реального аккаунта/результата.

Собирать только если выполняется хотя бы одно:

- в видео отсутствует критичный экран, который безопасно добрать;
- нужно воспроизвести code-backed риск;
- нужен Instruments trace;
- владелец отдельно просит build verification.

Timebox: 20 минут на зависимости + сборку. Failure записать как limitation и продолжить code/video audit. Дешёвую сверку version/build ↔ commit делать всегда, когда данные доступны.

## C. Simulator fallback

Использовать, когда видео нет либо нужно добрать конкретный state.

### Клон и scheme

```bash
git clone <git-user>@<git-host>:<repo-path>/<slug>.git <scratchpad>/<app>
# slug не найден:
ssh <git-user>@<git-host> ls <repo-path>/

cd <scratchpad>/<app>
WS=$(ls -d *.xcworkspace 2>/dev/null | head -1)
PROJ=$(ls -d *.xcodeproj 2>/dev/null | head -1)
if [ -n "$WS" ]; then FLAG=(-workspace "$WS"); else FLAG=(-project "$PROJ"); fi
xcodebuild "${FLAG[@]}" -list -json
SCHEME="<shared scheme from list>"
```

### Свежее устройство

```bash
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c "import json,sys;r=[x for x in json.load(sys.stdin)['runtimes'] if x['isAvailable'] and 'iOS' in x['name']];print(r[-1]['identifier'])")
DEVTYPE=$(xcrun simctl list devicetypes -j | python3 -c "import json,sys;d=[x for x in json.load(sys.stdin)['devicetypes'] if 'iPhone' in x['name']];print(d[-1]['identifier'])")
UDID=$(xcrun simctl create "audit-$(date +%s)" "$DEVTYPE" "$RUNTIME")
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
open -a Simulator
```

Нет runtime: `xcodebuild -downloadPlatform iOS`. Не скачивать ~8 ГБ без необходимости или уведомления владельца.

### Сборка без signing

```bash
xcodebuild "${FLAG[@]}" -scheme "$SCHEME" -destination "id=$UDID" -derivedDataPath ./dd build CODE_SIGNING_ALLOWED=NO
SETTINGS="$(xcodebuild "${FLAG[@]}" -scheme "$SCHEME" -destination "id=$UDID" -derivedDataPath ./dd -showBuildSettings 2>/dev/null)"
APP="$(echo "$SETTINGS" | awk -F' = ' '/WRAPPER_EXTENSION = app$/{ok=1} /TARGET_BUILD_DIR/{d=$2} /FULL_PRODUCT_NAME/{n=$2} ok&&d&&n{print d"/"n; exit}')"
BID=$(defaults read "$APP/Info" CFBundleIdentifier)
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$BID"
```

CocoaPods/entitlements/secrets/license могут заблокировать сборку. Зафиксировать точную причину; по истечении timebox не чинить чужой проект в рамках аудита.

### Скриншоты и гейты

```bash
mkdir -p "$SHOTS"
xcrun simctl io "$UDID" screenshot "$SHOTS/NN-screen.png"
xcrun simctl spawn "$UDID" defaults write "$BID" onboarding_completed -bool true
xcrun simctl addmedia "$UDID" <image>
```

ATT при выключенном устройстве:

```bash
sqlite3 ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/TCC/TCC.db "INSERT OR REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,flags) VALUES ('kTCCServiceUserTracking','$BID',0,2,2,1,0);"
```

- Ключи `defaults` сначала найти в коде, не угадывать.
- Push permission требует тапа; камера в Simulator может дать ожидаемый error-state.
- Если доступен владелец у открытого Simulator и у агента нет прямого UI-control: одной строкой назвать текущий экран и одно действие; дождаться ответа «готово»; сразу снять screenshot; проверить смену состояния. Несколько тапов проводить по одному, сохраняя каждый экран.
- Если интерактивного тапа нет: не зависать; записать state как not covered и что именно требуется.

## D. Analytics hygiene

Simulator launch может отправить fake install/events в Adjust, Adapty, Firebase и другие production dashboards.

- По возможности отключить сеть Simulator.
- Иначе заранее записать device id, bundle id и точное время для фильтрации.
- Видео с личного устройства владельца не создаёт дополнительной сессии.
- Не инициировать покупку, review submission, push send или production write без явного разрешения.
