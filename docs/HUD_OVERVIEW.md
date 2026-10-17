# MT SmartWatch Framework — HUD Subsystem Documentation

> **Для ИИ-агентов и контрибьюторов.** Project Zomboid **Build 42.21**.
> Прочитай целиком перед изменениями — здесь все актуальные грабли и решения.
> **Единый живой документ.** Все изменения — через раздел «Changelog» в шапке.

---

## 0. Changelog

### v4 (текущая)
- **Добавлен Тактический Хотбар** (`HUD_TacticalSlots.lua`): слоты для чипов, drag&drop, привязка к ядру.
- **Кулдауны чипов**: эффект часов (clock-sweep), пульсирующая обводка, цифровой таймер.
- **Состояние "Нет батарейки"**: темный тинт + иконка пустой батарейки с пульсацией (приоритет ниже КД).
- **Настройки хотбара** (`HUD_SettingsPanel_Hotbar.lua`): Scale, Gap, Fade, Line Position (Top/Bottom), Lock (Pin).
- **Декоративная полоса (Line)**: 3-slice рендер (Left/Center/Tail), сдвиг, текст `Battery Status: N \ X`.
- **Важно**: `Battery.getCurrent` вызывается через точку (это функция модуля, не метод объекта).
- **Известные баги**: Текст `Battery Status` не ресайзится, отступы при переключении полосы Top/Bottom кривые.

### v3
- **Новая архитектура иконки**: базовая (`OnScreenSmartWatchHUD.png`) + опциональные слои (`_Circle`, `_Battery_*`).
- **Circle (кольцо ядра)** — вращающийся слой, появляется при наличии OS Core.
- **Battery** — 5 тиров, текст %, пульсация при `<5%`.
- **Настройки**: Circle speed (Never/Slow/Medium/Fast) и Circle direction (Left/Right) в ПКМ-панели.
- **Критично для B42.21**: `DrawTextureAngle` — единственный рабочий API вращения; не масштабирует текстуру → нужны 3 PNG круга (256/128/64).
- **Оптимизация**: кэш `MeasureStringX`, `getFontHeight`, поиск tier — только при смене целого %.

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
**Задача HUD:** показывать иконку при надевании часов `mtsw:smartwatch`; при наличии ядра — кольцо, батарейка, %; ПКМ → панель настроек. При наличии ядра также появляется Тактический хотбар для быстрого доступа к чипам.

**Связанные модули в `shared/`:**
- `Watch.lua` — `Watch.isSmartWatch(item)`, `Watch.getEquippedWatch(player)`
- `OSCore.lua` — `OSCore.hasInstalledCore(watch)`, `OSCore.getInstalledData(watch)`
- `ChipSystem.lua` — `ChipSystem.getInstalledChips(watch)`, `getActiveChips`, `setHotbarSlot`, `getHotbarSlots`, `activateChip`
- `Battery.lua` — `Battery.getCurrent/Max/Percent(watch)`, `Battery.isEmpty(watch)`
- `BatteryDrain.lua` — пассивный слив заряда, тик раз в игровую минуту
- `TacticalChipRegister.lua` — реестр тактических чипов (содержит `onActivate` и `getCooldown`)

---

## 2. Структура HUD

```text
[MT] SmartWatchFramework/42/
├── media/
│   ├── lua/
│   │   ├── client/
│   │   │   └── MT_SmartWatchFramework/
│   │   │       └── HUD/
│   │   │           ├── HUD_Init.lua                        ← entry point
│   │   │           ├── HUD_State.lua                       ← runtime + Settings + .ini
│   │   │           ├── HUD_Base.lua                        ← базовый класс (fade, drag, pin)
│   │   │           ├── HUD_Icon.lua                        ← иконка + Circle + Battery-вызов
│   │   │           ├── HUD_Battery.lua                     ← рендер батарейки + % + пульс
│   │   │           ├── HUD_SettingsPanel_WatchOnScreen.lua ← ПКМ-панель часов
│   │   │           ├── HUD_TacticalSlots.lua               ← Хотбар (слоты, КД, полоса)
│   │   │           ├── HUD_SettingsPanel_Hotbar.lua        ← ПКМ-панель хотбара
│   │   │           ├── HUD_Interface.lua                   ← Главное окно часов (ЛКМ)
│   │   │           ├── HUD_Interface_TacticalChips.lua     ← Список чипов для Drag&Drop
│   │   │           └── HUD_ModOptions.lua.disabled         ← архив (MODS отключён)
│   │   └── shared/
│   │       ├── MT_SmartWatchFramework/                     ← Watch, OSCore, ChipSystem, Battery, BatteryDrain, Registers
│   │       └── Translate/{EN,RU}/ui.json
│   └── UI/
│       ├── OnScreenSmartWatchHUD/
│       │   ├── OnScreenSmartWatchHUD.png                   ← 256×256, база
│       │   ├── OnScreenSmartWatchHUD_Circle.png            ← 256×256, кольцо
│       │   ├── OnScreenSmartWatchHUD_Circle_128.png        ← 128×128
│       │   ├── OnScreenSmartWatchHUD_Circle_64.png         ← 64×64
│       │   ├── OnScreenSmartWatchHUD_Battery_100.png       ← 75–100%
│       │   ├── OnScreenSmartWatchHUD_Battery_75.png        ← 50–75%
│       │   ├── OnScreenSmartWatchHUD_Battery_50.png        ← 25–50%
│       │   ├── OnScreenSmartWatchHUD_Battery_25.png        ← 5–25%
│       │   └── OnScreenSmartWatchHUD_Battery_5.png         ← <5% (пульс)
│       └── OnScreenTacticalPanelHUD/
│           ├── OnScreenTacticalPanelHUD_SlotEmpty.png      ← Пустой слот (84x84)
│           ├── OnScreenTacticalPanelHUD_BatteryEmpty.png   ← Иконка пустой батарейки (84x84)
│           ├── OnScreenTacticalPanelHUD_LockOpen.png       ← Замок открыт (TODO)
│           ├── OnScreenTacticalPanelHUD_LockClosed.png     ← Замок закрыт (TODO)
│           ├── OnScreenTacticalPanelHUD_LineLeft.png       ← Полоса левая (TODO)
│           ├── OnScreenTacticalPanelHUD_LineCenter.png     ← Полоса центр (TODO)
│           └── OnScreenTacticalPanelHUD_LineTail.png       ← Полоса хвост (TODO)
```

---

## 3. Роли файлов

| Файл | Роль |
|------|------|
| **`HUD_Init.lua`** | Entry point. `require` модулей. Singleton иконки и хотбара. Троттлинг `OnPlayerUpdate` (8 кадров). `OnGameStart`, `OnPlayerDeath`. |
| **`HUD_State.lua`** | `MT_SmartWatch.HUD.State` + `Settings`. Чтение/запись `.ini`. `State.update(player)` (watch, hasOSCore, chips, batteryPercent). |
| **`HUD_Base.lua`** | Базовый класс (ISUIElement). Fade, drag, pin, hover, click. |
| **`HUD_Icon.lua`** | Класс иконки часов. Рисует базу + кольцо + вызывает `Battery.render()`. Анимация кольца. |
| **`HUD_Battery.lua`** | Модуль-рендерер батарейки. Выбор тира, кэш, пульс `<5%`. |
| **`HUD_SettingsPanel_WatchOnScreen.lua`** | ПКМ-панель часов: Pin, Icon size, Fade, Circle speed/direction. |
| **`HUD_TacticalSlots.lua`** | Отрисовка слотов, логика Drag&Drop, кулдауны (clock-sweep), пустая батарейка, отрисовка полосы и текста статуса. |
| **`HUD_SettingsPanel_Hotbar.lua`** | ПКМ-панель хотбара: Pin, Scale, Gap, Fade, Line Position. |
| **`HUD_Interface.lua`** | Окно интерфейса часов (кнопка "Тактические чипы"). |
| **`HUD_Interface_TacticalChips.lua`** | Список установленных чипов для перетаскивания на хотбар. |

---

## 4. Архитектурные правила

### 4.1. Namespace
- `MT_SmartWatch.HUD.State` / `.Settings` — данные
- `MT_SmartWatch.HUD.Base / Icon / SettingsPanel_WatchOnScreen / TacticalSlots` — модули
- `MT_SmartWatch.HUD.icon` / `.tacticalSlots` — синглтоны UI
- `MT_SmartWatch.HUD.dragPreview` — синглтон превью для Drag&Drop

### 4.2. Имена классов
`:derive("MT_SmartWatch_HUD_XXX")` — полный префикс.

### 4.3. Лог-префикс
`[MT Smart Watch - HUD]` для grep. **Только ASCII в `print()`.**

### 4.4. Хранилище
- **Единственный источник правды**: `Zomboid/MT_SmartWatch_HUD.ini`
- **Runtime** — обновляется каждые 8 кадров через `State.update(player)`.

### 4.5. Переводы
- Ключи `UI_MTSW_HUD_*` в `Translate/{EN,RU}/ui.json`. Trailing comma разрешена.

---

## 5. ⚠️ Критические грабли (B42.21)

### 5.1. `ISUIElement` / `ISPanel` не загружены
Отложенное создание через `Events.OnGameBoot`. Если `FATAL` в OnGameBoot — Verify Integrity Steam.

### 5.2. `getTimeStep()` не существует
Использовать `getTimestampMs()` (fallback `getTimeInMillis()`).
```lua
local dt = (nowMs - self._lastMs) / 1000
if dt > 0.25 then dt = 0.016 end
```

### 5.3. Drag feedback loop
Использовать **экранные** `getMouseX()` (не `self:getMouseX()`).

### 5.4. Обязательны все 4 метода drag
`onMouseMove`, `onMouseUp`, `onMouseMoveOutside`, `onMouseUpOutside` + `setCapture`.

### 5.5. `getFileWriter` allowlist
Только `.ini`, `.cfg`, `.txt`, `.log`.

### 5.6. `Battery.getCurrent` — функция, а не метод!
Вызывать **только через точку**: `Battery.getCurrent(watch)`.
Если написать `Battery:getCurrent(watch)` — упадёт `Object tried to call nil` (в watch передастся таблица модуля).

### 5.7. 🚨 Вращение текстуры (Circle)
`javaObject.DrawTextureAngle(tex, cx, cy, angleDeg)` — единственный рабочий API. Угол в **градусах**, не масштабирует. Поэтому 3 PNG для круга.

### 5.8. 🚨 Текст и его масштабирование (Tactical Hotbar)
`drawTextScaled` либо не работает, либо работает криво. В B42 попытка уменьшить текст через `textScale = 0.5 * scale` приводит к визуальным артефактам. Пока что оставлен базовый `UIFont.Small`.

### 5.9. Кириллица в `print()`
Всегда ASCII.

---

## 6. Настройки (.ini)

Файл: `Zomboid/MT_SmartWatch_HUD.ini`
```ini
VERSION=10
# Icon Settings
iconSize=128
fadeTime=0
circleSpeed=3
circleDirection=2
# Tactical Hotbar Settings
tacticalLock=false
tacticalScale=1.0
tacticalGap=2.5
tacticalFadeTime=0
tacticalLinePosition=bottom
# Positions
icon.x=1500
icon.y=20
icon.pinned=false
tacticalSlots.x=...
tacticalSlots.y=...
tacticalSlots.pinned=false
```

| Ключ | Значения | По умолчанию |
|------|----------|-------------|
| `VERSION` | 10 (текущая) | — |
| `iconSize` | 256 / 128 / 64 | 128 |
| `fadeTime` | 0 = Never, 0.5 / 1 / 2 / 3 / 4 / 5 / 6 | 0 |
| `circleSpeed` | 1=Never, 2=Slow, 3=Medium, 4=Fast | 3 |
| `circleDirection` | 1=Left, 2=Right | 2 |
| `tacticalLock` | true / false | false |
| `tacticalScale` | 0.5 / 0.75 / 1.0 / 1.25 / 1.5 | 1.0 |
| `tacticalGap` | 0 / 2.5 / 5 / 7.5 / 10 | 2.5 |
| `tacticalFadeTime` | 0 = Never, 0.5 .. 6 | 0 |
| `tacticalLinePosition` | "bottom" / "top" | "bottom" |

Несовпадение `VERSION` → полный сброс layout-настроек.

---

## 7. Поток событий

```text
OnGameBoot:
  → HUD_Base.buildBaseClass()
  → HUD_SettingsPanel.buildPanelClass()
  → HUD_TacticalSlots.buildClass()

OnGameStart:
  → State.load()  (читает .ini)

OnPlayerUpdate (каждые 8 кадров):
  → State.update(player)
  → ensureIcon()
  → ensureTacticalSlots()
  → Обновление видимости и данных

Icon:render() каждый кадр:
  → Отрисовка иконки, круга, батарейки

TacticalSlots:render() каждый кадр:
  → Отрисовка полосы + текста статуса
  → Отрисовка слотов + чипов (с учетом КД и Батарейки)

ЛКМ на иконке:
  → MT_SmartWatch.HUD.openInterface()

ПКМ на иконке / хотбаре:
  → openSettingsPanel_WatchOnScreen / openHotbarSettingsPanel
  → Save: Settings → State.save() → .ini
```

---

## 8. Ключи перевода

| ID | EN | RU |
|----|----|----|
| `UI_MTSW_HUD_Title` | MT SmartWatch | MT SmartWatch |
| `UI_MTSW_HUD_PinIcon` | Pin icon | Закрепить |
| `UI_MTSW_HUD_IconSize` | Icon size | Размер иконки |
| `UI_MTSW_HUD_FadeTime` | Fade time | Время до исчезновения |
| `UI_MTSW_HUD_Save` | Save | Сохранить |
| `UI_MTSW_HUD_Fade_*` | Never / 0.5..6 sec | Никогда / 0.5..6 сек |
| `UI_MTSW_HUD_CircleSpeed` | Circle speed | Скорость вращения |
| `UI_MTSW_HUD_CircleDirection`| Circle direction | Направление вращения |
| `UI_MTSW_HUD_Speed_*` | Never/Slow/Medium/Fast | Никогда/Медленно/Средне/Быстро |
| `UI_MTSW_HUD_Direction_*` | Left/Right | Влево/Вправо |
| `UI_MTSW_HUD_TacticalChips` | Tactical Chips | Тактические чипы |
| `UI_MTSW_HUD_NoChips` | No tactical chips installed | Тактические чипы не установлены |
| `UI_MTSW_HUD_HotbarTitle` | Tactical Hotbar | Тактический хотбар |
| `UI_MTSW_HUD_TacticalScale` | Scale | Масштаб |
| `UI_MTSW_HUD_TacticalGap` | Gap | Отступ |
| `UI_MTSW_HUD_LinePosition` | Line position | Позиция полосы |
| `UI_MTSW_HUD_LinePosition_Bottom`| Bottom | Снизу |
| `UI_MTSW_HUD_LinePosition_Top` | Top | Сверху |
| `UI_MTSW_EMP_ObjectBlocked` | I can't right now... | Сейчас не могу... |

---

## 9. Логика элементов

### 9.1. Иконка часов
- Показывается всегда при наличии часов. Одна текстура 256x256.
- При наличии ядра (`hasOSCore`):
  - **Circle**: вращается (3 PNG под размеры), скорость и направление из настроек.
  - **Battery**: 5 тиров (`100/75/50/25/5`). При `<5%` пульсирует только текстура батарейки. Текст % кэшируется.

### 9.2. Тактический хотбар (HUD_TacticalSlots)
- Появляется при `hasOSCore`. Количество слотов = `ChipSystem.getTacticalSlots(watch)`.
- **Управление**: Drag&Drop из `HUD_Interface_TacticalChips`. Свап и отвязка работают только если замок открыт.
- **Состояния чипа**:
  - Обычное (иконка).
  - **Кулдаун (приоритет 1)**: Clock-sweep тёмный тинт (снимается по часовой), пульсирующая обводка `#d92626`, серый текст таймера (M:SS).
  - **Нет батарейки (приоритет 2)**: Тёмный тинт, пульсирующая иконка пустой батарейки, мягкая обводка.
- **Полоса (Line)**:
  - Рисуется под/над слотами, сдвиг 25px вправо. 3-slice (Left/Center/Tail).
  - Рядом выводится текст `Battery Status: N \ X` (пока не скейлится).

---

## 10. Что работает

- ✅ Иконка часов + Кольцо (вращение) + Батарейка (5 тиров, пульс)
- ✅ Плавный Drag&Drop, Pin, сохранение в `.ini`
- ✅ ПКМ-панели для часов и хотбара
- ✅ Тактический хотбар появляется/исчезает по ядру
- ✅ Drag&Drop привязка/свап/отвязка чипов
- ✅ Активация чипов по ЛКМ через `ChipSystem.activateChip`
- ✅ Кулдауны (clock-sweep + текст + пульс)
- ✅ Состояние "Нет батарейки" (иконка + пульс)
- ✅ Настройки Scale, Gap, Line Position
- ✅ Локализация EN/RU
- ✅ Оптимизация кэша

---

## 11. TODO

### 🔴 Критические баги
- [ ] **0. Ресайз текста не работает!**
  - Текст `Battery Status` (и любые другие) не масштабируется вместе с `tacticalScale`. `drawTextScaled` работает криво. Нужно найти другой способ или забить.
- [ ] **0.1. Отступы при смене Top/Bottom неровные.**
  - При `tacticalLinePosition = "top"` математика `getSlotsOffsetY` и `recalcSize` даёт сбой: текст/слоты наезжают друг на друга или обрезаются.

### 🟡 Графика (нарисовать)
- [ ] **1. Иконка замка**: `LockOpen.png` и `LockClosed.png` (24x24 / 32x32).
- [ ] **2. Иконки полосы**: `LineLeft.png`, `LineCenter.png`, `LineTail.png` (с эффектом fade-in и хвостом).
- [ ] **3. Позиционирование полосы**: Вынести сдвиг `LINE_OFFSET_X = 25` в настройки.
- [ ] **4. Позиционирование текста**: Сделать независимым от Top/Bottom.
- [ ] **5. Визуал текста**: Добавить тень или сменить шрифт (Nier style).

### Будущее (Roadmap)
- [ ] `openInterface()` — полный интерфейс часов (слоты ядра и чипов).
- [ ] Хоткей для открытия интерфейса.
- [ ] Перевести HUD на родной логгер мода (убрать `[[MT] SmartWatchFramework]`).
- [ ] Индикатор памяти / батареи рядом с иконкой.
- [ ] Перерисовать иконку часов / сменить палитру на Nier Automata.
- [ ] **Индикатор количества выстрелов (например `x3`)** рядом со слотом.

---

## 12. Чек-лист при изменениях

- [ ] `MT_SmartWatch.HUD.*`
- [ ] `:derive("MT_SmartWatch_HUD_XXX")`
- [ ] Только ASCII в `print()`
- [ ] Lazy-build для `.derive`
- [ ] Drag: экранные координаты + 4 метода + `setCapture`
- [ ] Вращение: `javaObject:DrawTextureAngle(tex, cx, cy, angleDeg)`
- [ ] `Battery.getCurrent(watch)` — только через точку!
- [ ] Хранилище: `.ini`
- [ ] Переводы `UI_MTSW_HUD_*`

---

## 13. Формат апдейтов

При обновлении:
1. Правь этот файл напрямую (добавь запись в Changelog).
2. Или создай `update_N.md` для отдельной фичи.

---

## 14. Быстрые ссылки

- Reference-моды: `SurvivalHUD`, `MiniHealthPlus`
- PZ Wiki Lua Events: https://pzwiki.net/wiki/Lua_Event
- Файл настроек: `Zomboid/MT_SmartWatch_HUD.ini`