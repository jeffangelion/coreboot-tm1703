# TM1703: аудит происхождения данных

Дата аудита: 2026-10-26

## Область и критерий

Цель аудита — отделить параметры, которые можно воспроизвести по открытым
исходникам, опубликованной документации и наблюдениям за собственным железом,
от сведений, ранее полученных при анализе OEM PEI/ACPI.

Во время предыдущей работы выполнялась декомпиляция `ProgramGPIOPei` в Ghidra.
Полученный результат не переносился в `src/`, но участник реализации был с ним
ознакомлен. Поэтому строгую классическую clean-room независимость для будущей
реализации полной GPIO-таблицы заявлять нельзя. Эти сведения запрещено
использовать; каждое значение должно иметь независимый источник из списка ниже.

## Результат аудита

| Подсистема или параметр | Текущее происхождение | Независимый источник | Статус |
| --- | --- | --- | --- |
| IFD/ME/EC и flash layout | Собственный SPI-дамп, `ifdtool`, сравнение T48 | Повторные аппаратные дампы и стандартные flash-структуры | Подтверждено |
| VBT | Извлечён как data blob из собственного BIOS/системы | `/sys/kernel/debug/dri/0/i915_vbt`, VBT decoder и хеш | Воспроизводимо без анализа кода |
| PCIe RP1/RP5/RP9 | `lspci` работающей OEM-системы | PCI topology и аппаратные IDs | Подтверждено |
| PCIe CLKREQ | Ранее выбраны по FSP/default mapping | Runtime PM показал RP1→CLKREQ0; active NVMe коррелирует с CLKREQ2; Linux debugfs показал, что native включён только для CLKREQ0..2; открытый Tianocore KBL код описывает точную FIA DRCRM register map | RP1 подтверждён; RP5/RP9 наиболее вероятно используют CLKREQ1/2; текущие RP5→3 и RP9→5 исключены pad configuration; для окончательной проверки нужен FIA PCR snapshot |
| Display GPIO E13/E17/E18/E19 | Ранее описаны как восстановленные из OEM PEI | OEM `inteltool` dump и открытая Intel KBL RVP GPIO table дают те же mode/pull/reset | Независимо подтверждено |
| SPD для установленного Samsung модуля | OEM data blob и SMBIOS model | SPD fields/CRC, SMBIOS и успешное FSP training | Практически подтверждено |
| Девять SPD-вариантов | Извлечение data blobs из BIOS | Datasheets или физические экземпляры каждого SKU | Сами SPD являются данными; полный набор SKU требует дополнительного подтверждения |
| Полная strap→SPD таблица | Ранее восстановлена из OEM PEI | Наблюдения GPIO и памяти на нескольких SKU либо схема/boardview | Не подтверждено |
| DQ byte map | Ранее связывалась с OEM PEI | Точно совпадает с публичным Kaby Lake FSP default; CH0 также есть в Intel KBL RVP/coreboot | Независимо подтверждено |
| DQS identity map | Ранее получена из OEM PEI | Нужны схема/boardview либо независимая серия memory-training tests | Не подтверждено |
| Rcomp `{200,81,162}` и `{100,40,40,23,40}` | Ранее названы OEM values | Точно совпадают с Kaby Lake FSP defaults и несколькими открытыми coreboot-портами | Независимо подтверждено |
| `DqPinsInterleaved = 1` | Гипотеза и аппаратный эксперимент | При `0` FSP возвращает ошибку, при `1` память обучается; поле документировано FSP | Независимо подтверждено экспериментом |
| `CaVrefConfig = 0` | Ранее связывалась с OEM config | Kaby Lake FSP default и описание FSP BSF | Независимо подтверждено как референсное значение |
| HDA pin config | OEM/live codec data | Linux codec sysfs/proc dump и стандартные HDA verbs | Воспроизводимо без анализа кода |
| EC ACPI memory map и battery fields | OEM DSDT/SSDT decompilation | Нужны открытые EC sources/spec, EC interface observations либо отдельная clean-room specification | Не подтверждено строгим clean-room способом |
| ME/reset diagnostics | PCI config/HFSTS и flashconsole | Intel register docs и наблюдаемое поведение | Подтверждено |
| Полная GPIO table и MX250 power/reset | Пока отсутствуют | Runtime PM локализовал GPU-сигналы до GPP_G1/G3/G4; порядок требует измерений | Частично подтверждено |

## Что можно получить честным путём

### GPIO

Без анализа OEM-кода можно восстановить значительную часть таблицы:

1. Преобразовать собственный `inteltool -g` dump штатной системы с помощью
   coreboot `util/intelp2m`. Это даёт mode, native function, pull, reset domain,
   interrupt routing и текущее значение каждого PCH pad.
2. Сверить native pads с Kaby Lake FSP headers, Intel KBL RVP и существующими
   coreboot-портами.
3. Снять несколько read-only snapshots: cold boot, стабильная работа, MX250
   runtime-suspend/resume и S3. Различия локализуют динамические power/reset
   outputs без знания OEM реализации.
4. Подтвердить потенциальные rail/reset GPIO измерениями мультиметром или
   логическим анализатором. До подтверждения не программировать выходные pads.
5. Для MX250 дополнительно использовать PCI presence/link state и доступные
   OS power-state interfaces как чёрный ящик.

Один поздний `inteltool` dump достаточен для native pads и неопасных inputs,
но недостаточен для безопасного определения полярности и последовательности
выходов питания.

### Memory init

Почти всё уже имеет открытое подтверждение в
`3rdparty/fsp/KabylakeFspBinPkg/Fsp.bsf` и существующих coreboot-портах.
Исключение — identity DQS map и полная таблица SKU straps. Для текущей платы
их можно заменить независимо обоснованной конфигурацией после контролируемых
memory-training tests; для поддержки всех SKU нужны дополнительные экземпляры
плат либо схема/boardview.

### ACPI и EC

Стандартные ACPI устройства и методы можно реализовать по ACPI specification,
EDK2 и существующим GPL coreboot-портам. Board-specific EC offsets, event codes
и shared-memory layout из этого не следуют. Для них нужен один из вариантов:

- опубликованный исходник или спецификация EC;
- read-only трассировка документированного интерфейса EC из ОС;
- независимая функциональная спецификация от отдельного исследователя;
- собственные аппаратные эксперименты с наблюдением входов и результатов.

До появления такого источника текущий `acpi/ec.asl`, прямо основанный на OEM
SSDT, нельзя считать строго clean-room реализацией.

## Роль EDK2

Открытые исходники EDK2 полезны как референс для стандартных UEFI/PI/ACPI
интерфейсов и общих алгоритмов. Generic EDK2 из дерева coreboot не содержит
board-specific данных TM1703. Наиболее полезны будут открытые Intel
KabyLakeSiliconPkg/KabyLakeOpenBoardPkg или другой совместимый пакет с GPIO,
FSP UPD и reference-board policy.

Перед использованием дополнительных исходников нужно проверить их лицензию и
происхождение. Они могут подтвердить формат и референсные defaults, но не могут
сами по себе доказать разводку GPIO, DQS или EC memory map конкретной TM1703.

## Практический вывод

Продолжать порт без OEM-декомпиляции реально. Для базовой загрузки уже есть
достаточно чисто воспроизводимых данных. Главные пробелы — безопасная
идентификация GPIO питания/reset, identity DQS map, полная SPD strap table и
board-specific EC ACPI. Для следующего GPIO-этапа следует использовать только
`inteltool`/`intelp2m`, открытые KBL reference sources и измерения, сохраняя для
каждой добавленной строки источник подтверждения.
