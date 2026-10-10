# MT SmartWatch Framework — HUD Subsystem Documentation (v2)

> **Для ИИ-агентов и контрибьюторов.** Project Zomboid **Build 42.21**.
> Прочитай целиком перед изменениями — здесь все актуальные грабли и решения.

---

## 0. Changelog

### v2 (текущая)
- Настройки HUD перенесены из вкладки **MODS** в **ПКМ-панель** на иконке.
- Единственный источник правды — `Zomboid/MT_SmartWatch_HUD.ini`.
- `HUD_ModOptions.lua` **отключён** (`.lua.disabled` или `return` первой строкой).
- Добавлены переводы: `UI_MTSW_HUD_*` (EN + RU).
- Добавлена функция `MT_SmartWatch.HUD.openSettingsPanel(icon)`.

### v1
- Первая реализация иконки с fade + drag + pin.

---

## 1. Контекст проекта

**Мод:** `[MT] SmartWatchFramework` (Project Zomboid B42.21)
**Репозиторий:** https://github.com/yatsureru/-MT-SmartWatch
**Задача HUD:** показывать иконку, когда на игроке часы с тегом `mtsw:smartwatch`.
Иконка меняется (Empty / OScore), таскается, fade по таймеру, ПКМ → панель настроек.

**Связанные модули в `shared/`:**
- `Watch.lua` — `Watch.isSmartWatch(item)`, `Watch.getEquippedWatch(player)`
- `OSCore.lua` — `OSCore.hasInstalledCore(watch)`, `OSCore.getInstalledData(watch)`
- `ChipSystem.lua` — `ChipSystem.getInstalledChips(watch)`, `ChipSystem.getActiveChips(watch)`
- Реестры: `OSCoreRegister`, `AppChipRegister`, `FunctionalChipRegister`, `TacticalChipRegister`

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
│   │   │           ├── HUD_Base.lua                     ← базовый класс
│   │   │           ├── HUD_Icon.lua                     ← иконка (Empty / OScore)
│   │   │           ├── HUD_SettingsPanel.lua            ← ПКМ-панель
│   │   │           └── HUD_ModOptions.lua.disabled      ← архив (MODS отключён)
│   │   └── shared/
│   │       ├── MT_SmartWatchFramework/                  ← Watch, OSCore, ChipSystem...
│   │       └── Translate/
│   │           ├── EN/ui.json                           ← ключи UI_MTSW_HUD_*
│   │           └── RU/ui.json
│   └── UI/
│       └── OnScreenSmartWatchHUD/
│           ├── OnScreenSmartWatchHUD_Empty.png          (1024×1024)
│           └── OnScreenSmartWatchHUD_OScore.png         (1024×1024)
```

---

## 3. Роли файлов

| Файл | Роль |
|------|------|
| **`HUD_Init.lua`** | Entry point. `require` модулей. Singleton-иконки. Троттлинг `OnPlayerUpdate` (8 кадров). `OnGameStart → State.load()`. `OnPlayerDeath → скрыть`. Точка `openInterface()`. |
| **`HUD_State.lua`** | `MT_SmartWatch.HUD.State` + `Settings`. Чтение/запись `MT_SmartWatch_HUD.ini`. `State.update(player)` — watch/hasOScore/coreData/chips. |
| **`HUD_Base.lua`** | Класс `MT_SmartWatch_HUD_Base` (ISUIElement). Fade, drag, pin, hover, click, context-menu hook. |
| **`HUD_Icon.lua`** | Класс `MT_SmartWatch_HUD_Icon`. Рисует Empty/OSCore. ЛКМ → `openInterface()`. ПКМ → `openSettingsPanel()`. |
| **`HUD_SettingsPanel.lua`** | Класс `MT_SmartWatch_HUD_SettingsPanel`. Pin/Size/Fade + Save. Drag за шапку. |
| **`HUD_ModOptions.lua.disabled`** | Архив. Включить: убрать `.disabled` + вернуть `require` в `HUD_Init.lua`. |

---

## 4. Архитектурные правила

### 4.1. Namespace
- `MT_SmartWatch.HUD.State` — рантайм
- `MT_SmartWatch.HUD.Settings` — настройки
- `MT_SmartWatch.HUD.Base / Icon / SettingsPanel` — классы
- `MT_SmartWatch.HUD.icon` — singleton иконки
- `MT_SmartWatch.HUD.settingsPanelInstance` — singleton панели

### 4.2. Имена классов
`:derive("MT_SmartWatch_HUD_XXX")` — полный префикс. **Не** `MTSW_`, **не** `HUD_`.

### 4.3. Лог-префикс
`[MT Smart Watch - HUD]` для grep.
⚠️ Известная косметика: `Debug.lua` в моде оборачивает `print` и добавляет `[[MT] SmartWatchFramework]` — получается двойной префикс. **TODO:** перевести HUD на родной логгер мода (`MT_SmartWatch.Debug.log` или аналог), когда решим.

### 4.4. Хранилище
- **Единственный источник правды** для настроек: `Zomboid/MT_SmartWatch_HUD.ini`.
- **`PZAPI.ModOptions`** — отключён, MODS-вкладка удалена.
- **Runtime** (watch/chips/core) — каждый `OnPlayerUpdate` через `State.update(player)`.
- **Реестры контента** — в `shared/`, **не дублировать в HUD**.

### 4.5. Переводы
- Ключи префикса `UI_MTSW_HUD_*` в `media/lua/shared/Translate/{EN,RU}/ui.json`.
- Хелпер `L(key, fallback)` = `getTextOrNull(key) or fallback`.
- ⚠️ **В JSON переводах PZ разрешает trailing comma** — ставь запятую после последнего ключа на всякий случай.

---

## 5. ⚠️ Критические грабли (B42.21)

### 5.1. `ISUIElement` / `ISPanel` не загружены на момент загрузки мода
Порядок: модовые `client/lua/**` **раньше** ванильных `ISUI/*`.
**Решение:** отложенное создание класса.
```lua
local function buildBaseClass()
    if not ISUIElement then print("FATAL"); return end
    MT_SmartWatch.HUD.Base = ISUIElement:derive("MT_SmartWatch_HUD_Base")
    -- ...
end

if ISUIElement then buildBaseClass()
else Events.OnGameBoot.Add(buildBaseClass) end
```
**Норма:** `ISUIElement missing at load, deferring Base class to OnGameBoot`.
**Реальная ошибка:** `FATAL: ISUIElement still not available at OnGameBoot` — Verify Integrity.

### 5.2. `getTimeStep()` не существует в B42
Использовать `getTimestampMs()` → fallback `getTimeInMillis()` → `getTimestamp()*1000`.
```lua
local nowMs = getTimestampMs()
local dt = (nowMs - self._lastMs) / 1000
if dt > 0.25 then dt = 0.016 end   -- защита от фризов
self._lastMs = nowMs
```

### 5.3. Drag feedback loop
Использовать **экранные** `getMouseX()` (не `self:getMouseX()`).
`mouseDown` → `mouseDownScreenX = getMouseX()`.
`updateDrag` → `getMouseX() - mouseDownScreenX`.

### 5.4. Обязательны все 4 метода
`onMouseMove`, `onMouseUp`, `onMouseMoveOutside`, `onMouseUpOutside`. Без последних двух drag «залипает».

### 5.5. `setCapture(true/false)`
`onMouseDown` → `true`. `onMouseUp`/`onMouseUpOutside` → `false`.

### 5.6. `getFileWriter` allowlist
Только `.ini`, `.cfg`, `.txt`, `.log`. Используем `.ini`.

### 5.7. Троттлинг
`UPDATE_INTERVAL = 8` в `HUD_Init.onPlayerUpdate`. Не гонять `State.update` каждый кадр.

### 5.8. Hover-зона
`HOVER_SHRINK_PCT = 0.20` — сжимаем прямоугольник на 20% с каждой стороны, чтобы прозрачные края PNG не держали hover.

### 5.9. Двойной лог-префикс
См. 4.3. Оставить как TODO.

---

## 6. Настройки (.ini)

Файл: `Zomboid/MT_SmartWatch_HUD.ini`
```
VERSION=1
iconSize=128
fadeTime=0.5
icon.x=1500
icon.y=20
icon.pinned=false
```

| Ключ | Значения |
|------|----------|
| `VERSION` | `1`. Несовпадение → сброс позиции/pin, настройки остаются. |
| `iconSize` | `256` / `128` / `64` |
| `fadeTime` | `0` = Never, `0.5` / `1` / `2` / `3` / `4` / `5` / `6` |
| `icon.x`, `icon.y` | координаты |
| `icon.pinned` | `true` / `false` |

---

## 7. Поток событий

```
OnGameBoot:
  → HUD_Base.buildBaseClass()           (если ISUIElement уже есть)
  → HUD_SettingsPanel.buildPanelClass() (если ISPanel уже есть)

OnGameStart:
  → State.load()  (читает .ini — единственный источник правды)

OnPlayerUpdate (каждые 8 кадров):
  → State.update(player)  (watch, hasOScore, chips)
  → ensureIcon()
  → icon.visible = hasWatch
  → icon.useOScoreIcon = hasOScore

ЛКМ на иконке (без drag):
  → MT_SmartWatch.HUD.openInterface()   (заглушка, TODO)

ПКМ на иконке:
  → openSettingsPanel(icon)
  → Save: Settings → State.save() → .ini
  → закрыть панель

OnPlayerDeath:
  → icon.visible = false
  → settingsPanelInstance:close()
```

---

## 8. Ключи перевода

| ID | EN | RU |
|----|----|----|
| `UI_MTSW_HUD_Title` | MT SmartWatch | MT SmartWatch |
| `UI_MTSW_HUD_PinIcon` | Pin icon | Закрепить иконку |
| `UI_MTSW_HUD_IconSize` | Icon size | Размер иконки |
| `UI_MTSW_HUD_FadeTime` | Fade time | Время до исчезновения |
| `UI_MTSW_HUD_Save` | Save | Сохранить |
| `UI_MTSW_HUD_Fade_Never` | Never | Никогда |
| `UI_MTSW_HUD_Fade_05` | 0.5 sec | 0.5 сек |
| `UI_MTSW_HUD_Fade_1` | 1 sec | 1 сек |
| `UI_MTSW_HUD_Fade_2` | 2 sec | 2 сек |
| `UI_MTSW_HUD_Fade_3` | 3 sec | 3 сек |
| `UI_MTSW_HUD_Fade_4` | 4 sec | 4 сек |
| `UI_MTSW_HUD_Fade_5` | 5 sec | 5 сек |
| `UI_MTSW_HUD_Fade_6` | 6 sec | 6 сек |

---

## 9. Что работает

- ✅ Иконка появляется при надевании часов (`mtsw:smartwatch`)
- ✅ Иконка меняется при установке ядра (`OSCore`)
- ✅ Размер 256 / 128 / 64
- ✅ Fade `Never` / `0.5` / `1` / `2` / `3` / `4` / `5` / `6` сек
- ✅ Плавное перетаскивание (экранные координаты)
- ✅ Позиция сохраняется в `.ini`
- ✅ ПКМ → панель настроек (Pin/Size/Fade/Save)
- ✅ Pin отключает drag, но клик работает
- ✅ Пока панель открыта — иконка не исчезает (`forceVisible`)
- ✅ Локализация EN/RU
- ✅ MODS-вкладка удалена, конфликт источников правды устранён

---

## 10. TODO

- 🚧 `MT_SmartWatch.HUD.openInterface()` — полный интерфейс часов (слоты ядра/чипов).
- 🚧 Хоткей для открытия интерфейса.
- 🚧 Индикатор памяти/батареи рядом с иконкой.
- 🚧 Бейджи для уведомлений.
- 🚧 Перевести HUD на родной логгер мода (убрать двойной префикс).

---

## 11. Чек-лист при изменениях

- [ ] `MT_SmartWatch.HUD.*`, не свои глобалы
- [ ] `:derive("MT_SmartWatch_HUD_XXX")`
- [ ] Лог-префикс `[MT Smart Watch - HUD]`
- [ ] Lazy-build для нового `.derive`
- [ ] Drag → экранные координаты + 4 метода + `setCapture`
- [ ] Не вызывать `getTimeStep()`
- [ ] Хранилище — `.ini`
- [ ] Переводы через `UI_MTSW_HUD_*`
- [ ] Не дублировать логику `Watch.lua` / `OSCore.lua` / `ChipSystem.lua`

---

## 12. Формат апдейтов

Для новой итерации создавай `HUD_OVERVIEW_v3.md` (или `update3.md`):

```markdown
# Update 3 — <название>

## Что изменилось
- ...

## Файлы
- <путь> — <что поменялось>

## Новые API / ключи
- ...

## Грабли
- <новые — сюда>

## TODO
- ...
```

Приложи прошлую доку как контекст — ИИ мгновенно в курсе.

---

## 13. Быстрые ссылки

- Reference-моды: `SurvivalHUD` (thCraftMP), `MiniHealthPlus` (TwisTonFire)
- PZ Wiki Lua Events: https://pzwiki.net/wiki/Lua_Event
- Текущая версия HUD: `[MT Smart Watch - HUD] Init complete`