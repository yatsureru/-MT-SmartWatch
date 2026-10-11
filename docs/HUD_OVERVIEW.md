# MT SmartWatch Framework — HUD Subsystem Documentation

> **Для ИИ-агентов и контрибьюторов.** Project Zomboid **Build 42.21**.
> Прочитай целиком перед изменениями — здесь все актуальные грабли и решения.
> **Единый живой документ.** Все изменения — через раздел «Changelog» в шапке.

---

## 0. Changelog

### v3 (текущая)
- **Новая архитектура иконки**: базовая (`OnScreenSmartWatchHUD.png`) + опциональные слои (`_Circle`, `_Battery_*`).
- **Circle (кольцо ядра)** — вращающийся слой, появляется при наличии OS Core.
- **Battery** — 5 тиров, текст %, пульсация при `<5%`.
- **Настройки**: Circle speed (Never/Slow/Medium/Fast) и Circle direction (Left/Right) в ПКМ-панели.
- **Критично для B42.21**: `DrawTextureAngle` — единственный рабочий API вращения; не масштабирует текстуру → нужны 3 PNG круга (256/128/64).
- **Оптимизация**: кэш `MeasureStringX`, `getFontHeight`, поиск tier — только при смене целого %.
- Известный мелкий баг: кириллица в `print()` ломается на Windows → использовать только ASCII в логах.

### v2
- Настройки HUD перенесены из вкладки MODS в ПКМ-панель.
- Единственный источник правды — `Zomboid/MT_SmartWatch_HUD.ini`.
- `HUD_ModOptions.lua` отключён.
- Добавлены переводы `UI_MTSW_HUD_*`.

### v1
- Первая реализация иконки с fade + drag + pin.

---

## 1. Контекст проекта

**Мод:** `[MT] SmartWatchFramework` (Project Zomboid B42.21)
**Репозиторий:** https://github.com/yatsureru/-MT-SmartWatch
**Задача HUD:** показывать иконку при надевании часов `mtsw:smartwatch`; при наличии ядра — кольцо + батарейка + %; ПКМ → панель настроек.

**Связанные модули в `shared/`:**
- `Watch.lua` — `Watch.isSmartWatch(item)`, `Watch.getEquippedWatch(player)`
- `OSCore.lua` — `OSCore.hasInstalledCore(watch)`, `OSCore.getInstalledData(watch)`
- `ChipSystem.lua` — `ChipSystem.getInstalledChips(watch)`, `ChipSystem.getActiveChips(watch)`
- `Battery.lua` — `Battery.getCurrent/Max/Percent(watch)`, `Battery.isEmpty(watch)`
- `BatteryDrain.lua` — пассивный слив заряда, тик раз в игровую минуту

---

## 2. Структура HUD

```
[MT] SmartWatchFramework/42/
├── media/
│   ├── lua/
│   │   ├── client/
│   │   │   └── MT_SmartWatchFramework/
│   │   │       └── HUD/
│   │   │           ├── HUD_Init.lua                     ← entry point
│   │   │           ├── HUD_State.lua                    ← runtime + Settings + .ini
│   │   │           ├── HUD_Base.lua                     ← базовый класс (fade, drag, pin)
│   │   │           ├── HUD_Icon.lua                     ← иконка + Circle + Battery-вызов
│   │   │           ├── HUD_Battery.lua                  ← рендер батарейки + % + пульс
│   │   │           ├── HUD_SettingsPanel.lua            ← ПКМ-панель
│   │   │           └── HUD_ModOptions.lua.disabled      ← архив (MODS отключён)
│   │   └── shared/
│   │       ├── MT_SmartWatchFramework/                  ← Watch, OSCore, ChipSystem, Battery, BatteryDrain
│   │       └── Translate/{EN,RU}/ui.json
│   └── UI/
│       └── OnScreenSmartWatchHUD/
│           ├── OnScreenSmartWatchHUD.png                ← 256×256, база (всегда видна)
│           ├── OnScreenSmartWatchHUD_Circle.png         ← 256×256, кольцо ядра
│           ├── OnScreenSmartWatchHUD_Circle_128.png     ← 128×128 (из-за API)
│           ├── OnScreenSmartWatchHUD_Circle_64.png      ← 64×64   (из-за API)
│           ├── OnScreenSmartWatchHUD_Battery_100.png    ← 256×256, 75–100%
│           ├── OnScreenSmartWatchHUD_Battery_75.png     ← 256×256, 50–75%
│           ├── OnScreenSmartWatchHUD_Battery_50.png     ← 256×256, 25–50%
│           ├── OnScreenSmartWatchHUD_Battery_25.png     ← 256×256, 5–25%
│           └── OnScreenSmartWatchHUD_Battery_5.png      ← 256×256, <5% (пульс)
```

---

## 3. Роли файлов

| Файл | Роль |
|------|------|
| **`HUD_Init.lua`** | Entry point. `require` модулей. Singleton иконки. Троттлинг `OnPlayerUpdate` (8 кадров). `OnGameStart → State.load()`. `OnPlayerDeath`. Точка `openInterface()`. |
| **`HUD_State.lua`** | `MT_SmartWatch.HUD.State` + `Settings`. Чтение/запись `MT_SmartWatch_HUD.ini`. `State.update(player)` — watch / hasOSCore / coreData / chips / batteryPercent. |
| **`HUD_Base.lua`** | Класс `MT_SmartWatch_HUD_Base` (ISUIElement). Fade, drag, pin, hover, click. |
| **`HUD_Icon.lua`** | Класс `MT_SmartWatch_HUD_Icon`. Рисует базу + кольцо + вызывает `Battery.render()`. Управляет анимацией кольца (углы, скорости). |
| **`HUD_Battery.lua`** | Модуль-рендерер батарейки. Выбор тира, кэш текста %, пульс `<5%`. Вызывается **только** из `HUD_Icon:render()`, не отдельный UIElement. |
| **`HUD_SettingsPanel.lua`** | ПКМ-панель: Pin / Icon size / Fade time / Circle speed / Circle direction / Save. |
| **`HUD_ModOptions.lua.disabled`** | Архив. Включить: убрать `.disabled`, вернуть `require` в `HUD_Init.lua`. |

---

## 4. Архитектурные правила

### 4.1. Namespace
- `MT_SmartWatch.HUD.State` / `.Settings` — данные
- `MT_SmartWatch.HUD.Base / Icon / SettingsPanel / Battery` — модули
- `MT_SmartWatch.HUD.icon` — singleton иконки
- `MT_SmartWatch.HUD.settingsPanelInstance` — singleton панели

### 4.2. Имена классов
`:derive("MT_SmartWatch_HUD_XXX")` — полный префикс.

### 4.3. Лог-префикс
`[MT Smart Watch - HUD]` для grep.

⚠️ **Только ASCII в `print()`.** Кириллица ломается в Windows-консоли PZ (CP1251 vs UTF-8). Русский — только в `Translate/*.json` и в UI, который рендерит движок (`drawText`).

⚠️ В логе `[[MT] SmartWatchFramework]` — двойной префикс от модовой обёртки `print` в `Debug.lua`. Косметика. TODO: перевести HUD на родной логгер мода.

### 4.4. Хранилище
- **Единственный источник правды**: `Zomboid/MT_SmartWatch_HUD.ini`
- **`PZAPI.ModOptions`** — отключён
- **Runtime** — каждые 8 кадров через `State.update(player)`
- **Реестры контента** — в `shared/`, **не дублировать**

### 4.5. Переводы
- Ключи `UI_MTSW_HUD_*` в `Translate/{EN,RU}/ui.json`
- Хелпер `L(key, fallback)` = `getTextOrNull(key) or fallback`
- **Trailing comma** в JSON разрешена — ставить всегда

---

## 5. ⚠️ Критические грабли (B42.21)

### 5.1. `ISUIElement` / `ISPanel` не загружены на момент загрузки мода
**Решение:** отложенное создание класса через `Events.OnGameBoot`.
**Норма:** `ISUIElement missing at load, deferring Base class to OnGameBoot`.
**Реальная ошибка:** `FATAL: ISUIElement still not available at OnGameBoot` → Verify Integrity Steam.

### 5.2. `getTimeStep()` не существует в B42
Использовать `getTimestampMs()` → fallback `getTimeInMillis()` → `getTimestamp()*1000`.
```lua
local dt = (nowMs - self._lastMs) / 1000
if dt > 0.25 then dt = 0.016 end   -- защита от фризов
```

### 5.3. Drag feedback loop
Использовать **экранные** `getMouseX()` (не `self:getMouseX()`).
`mouseDown` → `mouseDownScreenX = getMouseX()`.
`updateDrag` → `getMouseX() - mouseDownScreenX`.

### 5.4. Обязательны все 4 метода drag
`onMouseMove`, `onMouseUp`, `onMouseMoveOutside`, `onMouseUpOutside`. + `setCapture(true/false)`.

### 5.5. `getFileWriter` allowlist
Только `.ini`, `.cfg`, `.txt`, `.log`.

### 5.6. Троттлинг `OnPlayerUpdate`
`UPDATE_INTERVAL = 8`.

### 5.7. Hover-зона
`HOVER_SHRINK_PCT = 0.20` — сжимаем на 20% с каждой стороны.

### 5.8. 🚨 **Масштабирование + вращение текстуры — главная засада B42.21**

Проверено диагностикой (`type()` для всех вариантов). **Результаты:**

| Метод | Наличие | Масштабирует? | Углы |
|-------|---------|---------------|------|
| `javaObject.DrawTextureScaledAngle` | ❌ nil | — | — |
| `javaObject.DrawTextureAngle` | ✅ function | ❌ **нет** | **градусы** |
| `self.drawTextureAngle` | ❌ nil | — | — |
| `self.drawTextureScaledAngle` | ❌ nil | — | — |
| глобальные `drawTextureAngle` / `drawTextureScaledAngle` | ❌ nil | — | — |
| `ISUIElement.setScale` / `self.setScale` / `self.scale` | ❌ nil | — | — |

**Единственный рабочий метод:**
```lua
javaObject:DrawTextureAngle(tex, cx, cy, angleDeg)
```
- угол — **градусы** (не радианы);
- anchor — **центр текстуры** (cx, cy — это точка вращения);
- **не масштабирует** — рисует текстуру в её **нативном размере**.

**Следствия:**

1. **Обычные элементы** (иконка, батарейки) — одна текстура **256×256** через `drawTextureScaled(tex, 0, 0, w, h, ...)`. Работает нормально, downscale на GPU даёт качественный результат.

2. **Круг (Circle) — единственный элемент, где нужны 3 PNG.** Потому что `DrawTextureAngle` не масштабирует. При `iconSize=128` рисуется `_Circle_128.png`, при 256 — `_Circle.png`, при 64 — `_Circle_64.png`. Выбор — в `Icon:drawCircle`:
   ```lua
   local size = self:getWidth()
   local tex  = self.texCircles[size] or self.texCircles[256]
   ```

3. **Если PZ когда-нибудь добавит `DrawTextureScaledAngle`** — 3 PNG круга можно вернуть к одному.

### 5.9. Кириллица в `print()`
Windows-консоль в CP1251 → любые русские символы превращаются в `??????`. **Всегда ASCII в логах.**

---

## 6. Настройки (.ini)

Файл: `Zomboid/MT_SmartWatch_HUD.ini`
```
VERSION=3
iconSize=128
fadeTime=0.5
circleSpeed=3
circleDirection=2
icon.x=1500
icon.y=20
icon.pinned=false
```

| Ключ | Значения | По умолчанию |
|------|----------|-------------|
| `VERSION` | 3 (текущая) | — |
| `iconSize` | 256 / 128 / 64 | 128 |
| `fadeTime` | 0 = Never, 0.5 / 1 / 2 / 3 / 4 / 5 / 6 | 0.5 |
| `circleSpeed` | 1 = Never, 2 = Slow (64с), 3 = Medium (32с), 4 = Fast (16с) | 3 |
| `circleDirection` | 1 = Left, 2 = Right | 2 |
| `icon.x`, `icon.y` | координаты | правый верх |
| `icon.pinned` | true / false | false |

Несовпадение `VERSION` → сброс позиции/pin/circleSpeed/circleDirection. IconSize и FadeTime сохраняются.

---

## 7. Поток событий

```
OnGameBoot:
  → HUD_Base.buildBaseClass()           (если ISUIElement уже есть)
  → HUD_SettingsPanel.buildPanelClass() (если ISPanel уже есть)

OnGameStart:
  → State.load()  (читает .ini — единственный источник правды)

OnPlayerUpdate (каждые 8 кадров):
  → State.update(player)  (watch, hasOSCore, chips, batteryPercent)
  → ensureIcon()
  → icon.visible = hasWatch
  → icon.hasOSCore = hasOSCore

Icon:render() каждый кадр:
  → getAnimDt()
  → updateHover() / updateAlpha(dt) / updateCircle(dt)
  → drawTextureScaled(texBase)
  → drawCircle()   [если hasOSCore]
  → Battery.render()  [если hasOSCore]

ЛКМ на иконке (без drag):
  → MT_SmartWatch.HUD.openInterface()   (заглушка, TODO)

ПКМ на иконке:
  → openSettingsPanel(icon)
  → Save: Settings → State.save() → .ini
```

---

## 8. Ключи перевода

| ID | EN | RU |
|----|----|----|
| `UI_MTSW_HUD_Title` | MT SmartWatch | MT SmartWatch |
| `UI_MTSW_HUD_PinIcon` | Pin icon | Закрепить иконку |
| `UI_MTSW_HUD_IconSize` | Icon size | Размер иконки |
| `UI_MTSW_HUD_FadeTime` | Fade time | Время до исчезновения |
| `UI_MTSW_HUD_CircleSpeed` | Circle speed | Скорость вращения |
| `UI_MTSW_HUD_CircleDirection` | Circle direction | Направление вращения |
| `UI_MTSW_HUD_Save` | Save | Сохранить |
| `UI_MTSW_HUD_Fade_Never` | Never | Никогда |
| `UI_MTSW_HUD_Fade_05` | 0.5 sec | 0.5 сек |
| `UI_MTSW_HUD_Fade_1`..`_6` | 1..6 sec | 1..6 сек |
| `UI_MTSW_HUD_Speed_Never` | Never | Никогда |
| `UI_MTSW_HUD_Speed_Slow` | Slow | Медленно |
| `UI_MTSW_HUD_Speed_Medium` | Medium | Средне |
| `UI_MTSW_HUD_Speed_Fast` | Fast | Быстро |
| `UI_MTSW_HUD_Direction_Left` | Left | Влево |
| `UI_MTSW_HUD_Direction_Right` | Right | Вправо |

---

## 9. Логика элементов иконки

### 9.1. Базовая иконка (`OnScreenSmartWatchHUD.png`)
- **Показывается всегда**, когда надеты часы.
- Одна текстура 256×256, рисуется через `drawTextureScaled(0, 0, w, h, alpha, 1, 1, 1)`.
- Никогда не меняется (в отличие от старой схемы `_Empty`/`_OScore`).

### 9.2. Кольцо (`_Circle*.png`)
- Появляется только при `hasOSCore = true`.
- Вращается со скоростью и направлением из Settings.
- Anchor — центр иконки. Угол — градусы.
- **3 файла** (256/128/64) из-за API-ограничения (см. 5.8).
- При `circleSpeed = 1 (Never)` — угол жёстко `0°`, статично (не «останавливается в случайном месте»).

### 9.3. Батарейка (`_Battery_*.png`)
- Показывается только при `hasOSCore = true` и `State.batteryPercent ~= nil`.
- 5 тиров по границам (нижняя включительно):

| % | Тиер | Текстура | Цвет текста |
|---|------|----------|-------------|
| ≥75 | 100 | `_Battery_100` | 🟢 зелёный |
| ≥50 | 75 | `_Battery_75` | 🟡 жёлтый |
| ≥25 | 50 | `_Battery_50` | 🟠 жёлто-оранжевый |
| ≥5 | 25 | `_Battery_25` | 🟠 оранжевый |
| <5 | 5 | `_Battery_5` | 🔴 красный + **пульс** |

- **Текст `NN%`** — справа от центра на 75px (native), по центру вертикали.
- **Кэш**: `icon._batCache` — пересчитывает `MeasureStringX`, `getFontHeight`, tier — только при смене целого %.
- **Проценты считаются от `Battery.getPercent(watch) = current / max * 100`**. Разные ядра дают разный `max` → «500 макс / 100 заряд = 20%».

### 9.4. Пульс при `<5%`
- `PULSE_PERIOD = 0.89 сек`, `PULSE_MIN_ALPHA = 0.05`.
- Пульсирует **только текстура батарейки** (`_Battery_5.png`), передаётся через `batteryPulseAlpha` в `Battery.render(icon, baseAlpha, textureAlpha)`.
- Базовая иконка, кольцо, текст — **не пульсируют**, `alpha = 1`.
- **`fadeTime` игнорируется** — иконка не затухает от бездействия, пока заряд критичен.

---

## 10. Что работает

- ✅ Иконка появляется при надевании часов `mtsw:smartwatch`
- ✅ Кольцо ядра появляется при установке ядра, вращается
- ✅ 4 скорости вращения (Never/Slow/Medium/Fast = 0/64/32/16 сек)
- ✅ 2 направления (Left/Right)
- ✅ Кольцо скейлится при смене `iconSize` (3 PNG)
- ✅ Батарейка 5 тиров + текст %
- ✅ Пульс `<5%` только на текстуре батарейки
- ✅ Fade `Never` / `0.5` / `1..6` сек
- ✅ Drag плавный (экранные координаты)
- ✅ Позиция сохраняется в `.ini`
- ✅ ПКМ-панель: Pin / Icon size / Fade time / Circle speed / Circle direction / Save
- ✅ Pin отключает drag, клик работает
- ✅ Пока панель открыта — иконка не исчезает (`forceVisible`)
- ✅ Локализация EN/RU
- ✅ Оптимизация: кэш текста %, tier, font height

---

## 11. TODO

### Текущие задачи
- [ ] **`openInterface()`** — полный интерфейс часов (слоты ядра и чипов) по ЛКМ.
- [ ] **Хоткей** для открытия интерфейса.
- [ ] **Исправить ASCII** в `print()` для `openInterface()` — сейчас там кириллица («полный интерфейс часов» → кракозябры).
- [ ] **Перевести HUD на родной логгер мода** — убрать двойной префикс `[[MT] SmartWatchFramework]`.

### Будущее (roadmap)
- [ ] **Перерисовать иконку часов полностью.**
- [ ] **Палитра кольца и батарейки в стиле Nier: Automata** — main colors круга и базы батарейки.
- [ ] **Новый HUD для тактических чипов** — панелька расширяется в зависимости от установленного ядра.
  - Уровни: `I`, `II`, `III`, `IV`, `V`
  - Количество слотов = capacity ядра (1..5)
  - Разные грейды ядер дают разную ёмкость по тактическим чипам
- [ ] **Индикатор памяти** рядом с иконкой.
- [ ] **Бейджи для уведомлений**.

---

## 12. Чек-лист при изменениях

- [ ] `MT_SmartWatch.HUD.*`, не свои глобалы
- [ ] `:derive("MT_SmartWatch_HUD_XXX")`
- [ ] Лог-префикс `[MT Smart Watch - HUD]`
- [ ] **Только ASCII** в `print()`
- [ ] Lazy-build для нового `.derive`
- [ ] Drag → экранные координаты + 4 метода + `setCapture`
- [ ] Не вызывать `getTimeStep()`
- [ ] Для вращения — только `javaObject:DrawTextureAngle(tex, cx, cy, angleDeg)` (градусы!)
- [ ] Если нужна масштабируемая вращающаяся текстура — пул PNG 256/128/64
- [ ] Хранилище — `.ini`
- [ ] Переводы через `UI_MTSW_HUD_*`
- [ ] Не дублировать логику `Watch.lua` / `OSCore.lua` / `ChipSystem.lua` / `Battery.lua`

---

## 13. Формат апдейтов

Для новой итерации:

1. **Правь этот файл напрямую:**
   - Добавь запись в раздел **0. Changelog** (новая версия наверху).
   - Обнови разделы 2/3/6/9/10/11 под текущее состояние.
2. **Или создай временный `update_N.md`** для отдельной фичи:
   ```markdown
   # Update N — <название>
   ## Что изменилось
   ## Файлы
   ## Новые API / ключи
   ## Грабли
   ## TODO
   ```
   После мерджа — перенеси содержимое в этот файл.

Приложи этот `.md` как контекст в новом чате с ИИ — он мгновенно в курсе.

---

## 14. Быстрые ссылки

- Reference-моды: `SurvivalHUD` (thCraftMP), `MiniHealthPlus` (TwisTonFire)
- PZ Wiki Lua Events: https://pzwiki.net/wiki/Lua_Event
- Текущая версия HUD: `[MT Smart Watch - HUD] Init complete`
- Файл настроек: `Zomboid/MT_SmartWatch_HUD.ini`