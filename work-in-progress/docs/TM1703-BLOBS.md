# TM1703: локальное получение firmware-компонентов

IFD, Intel ME и EC являются закрытыми компонентами заводской прошивки. Они не
добавляются в Git и должны быть извлечены пользователем из собственного 16-MiB
дампа SPI-флешки TM1703. VBT является разрешённым board-specific data-файлом и
поставляется в `src/mainboard/xiaomi/tm1703/data.vbt`.

## Подготовка

Все команды выполняются из корня дерева coreboot. Укажите путь к своему дампу:

```sh
tm1703_coreboot_dir=$PWD
tm1703_dump=$(realpath /path/to/tm1703-16mib.bin)
test "$(stat -c %s "$tm1703_dump")" -eq 16777216
tm1703_blob_dir=3rdparty/blobs/mainboard/xiaomi/tm1703
tm1703_extract_dir=$(mktemp -d)
mkdir -p "$tm1703_blob_dir"
make -C util/ifdtool
```

Используйте только собственный проверенный дамп, несколько раз одинаково
считанный внешним программатором. Не извлекайте эти файлы из случайного BIOS
update другого SKU.

## IFD, ME и EC

Карта исходного дампа:

```text
IFD  0x000000..0x000fff  0x001000 bytes
ME   0x001000..0x8fffff  0x8ff000 bytes
EC   0x900000..0x93ffff  0x040000 bytes
```

IFD и ME извлекаются штатным `ifdtool`, который получает их границы из самого
дескриптора:

```sh
(cd "$tm1703_extract_dir" && \
  "$tm1703_coreboot_dir/util/ifdtool/ifdtool" -x -p sklkbl "$tm1703_dump")
install -m 0644 "$tm1703_extract_dir/flashregion_0_flashdescriptor.bin" \
  "$tm1703_blob_dir/descriptor.bin"
install -m 0644 "$tm1703_extract_dir/flashregion_2_intel_me.bin" \
  "$tm1703_blob_dir/me.bin"
```

EC занимает board-specific диапазон, который не описан как EC-регион IFD,
поэтому для него остаётся отдельное извлечение:

```sh
dd if="$tm1703_dump" of="$tm1703_blob_dir/ec.bin" \
  bs=1 skip=$((0x900000)) count=$((0x040000)) status=none
```

Контрольные хеши эталонного заводского образа, использованного при разработке:

```text
descriptor.bin  c31e7f8f71a926ea1520193c6c10ee7bee944dd6adefd563d0997e910f854589
me.bin          de2577db37859027236bd3e1418148dcc1312e03ec008de95adc7086234d840b
ec.bin          58399fa5982b04e694ea676a6d95fd8a28d18fc3d7b774170ef338f1fd25b840
```

ME-регион внешнего runtime-дампа может отличаться из-за MFS. Не заменяйте его
другим ME-регионом только ради совпадения хеша; сохраняйте именно содержимое
своей платы и сначала разбирайтесь в причине различия.

## VBT

Для сборки используется поставляемый с платой файл
`src/mainboard/xiaomi/tm1703/data.vbt`. Его ожидаемый SHA-256:

```text
7aebcc9be9956903ff57e80c18cbff99866975d3e41c0debbe5807a9473eb0f5
```

Структуру можно проверить штатным `intelvbttool`:

```sh
make -C util/intelvbttool
util/intelvbttool/intelvbttool \
  --invbt src/mainboard/xiaomi/tm1703/data.vbt --outdump
```

Если исходником является Intel Option ROM, `intelvbttool --inoprom ...
--outvbt ...` извлекает из него raw VBT. Для сравнения с реально используемой
конфигурацией можно также снять live VBT из debugfs работающей стоковой системы.
Не подменяйте поставляемый файл VBT от другой платы или варианта панели.

## NVIDIA GeForce MX150 VBIOS

Дискретная видеокарта NVIDIA MX150 (GP108M `10de:1d12`) не имеет собственного чипа SPI flash
на материнской плате и получает VBIOS динамически через ACPI-метод `_ROM` (`\_SB.PCI0.RP01.PXSX._ROM`).
VBIOS извлекается из секции BIOS заводского дампа (FFS-файл с GUID `E35B2FEA-017C-47E8-AF17-C38CA2ED1F8B`).

В составе coreboot нет средств для разбора вложенных сжатых томов UEFI Firmware Volume,
поэтому для распаковки используется **сторонняя утилита** `uefiextract` из проекта
[UEFITool (LongSoft)](https://github.com/LongSoft/UEFITool) (готовые бинарные сборки доступны на
https://github.com/LongSoft/UEFITool/releases). Она не входит в репозиторий coreboot
и скачивается/собирается пользователем отдельно:

```sh
# Распаковка томов дампа внешней утилитой UEFIExtract:
uefiextract "$tm1703_dump"

# Копирование извлечённого сырого образа VBIOS (Raw section body.bin файла E35B2FEA...):
cp "$tm1703_dump.dump/2 BIOS region/1 1FD0BACE-6F0A-4085-901E-F6210385CB6F/0 20BC8AC9-94D1-4208-AB28-5D673FD73486/0 EE4E5898-3914-4259-9D6E-DC7BD79403CF/1 Volume image section/0 8C8CE578-8A3D-4F1C-9935-896185C32DD3/346 E35B2FEA-017C-47E8-AF17-C38CA2ED1F8B/0 Raw section/body.bin" \
  "$tm1703_blob_dir/pci10de,1d12.rom"
```

Ожидаемый размер: 180224 байт (0x2C000).
SHA-256 эталонного заводского VBIOS GP108 SKU 0 (версия 86.08.0E.00.5A):
```text
30971732921ec38e63edc2f71f6ee110ab0f560afe8b53b9fdd2abfc37e446b2
```

## Проверка перед сборкой

```sh
stat -c '%s %n' \
  "$tm1703_blob_dir/descriptor.bin" \
  "$tm1703_blob_dir/me.bin" \
  "$tm1703_blob_dir/ec.bin" \
  "$tm1703_blob_dir/pci10de,1d12.rom" \
  src/mainboard/xiaomi/tm1703/data.vbt
sha256sum \
  "$tm1703_blob_dir/descriptor.bin" \
  "$tm1703_blob_dir/me.bin" \
  "$tm1703_blob_dir/ec.bin" \
  "$tm1703_blob_dir/pci10de,1d12.rom" \
  src/mainboard/xiaomi/tm1703/data.vbt
```

Ожидаемые размеры: 4096, 9433088, 262144, 180224 и 4441 байт соответственно. IFD, ME,
EC и dGPU VBIOS остаются локальными и незатреканными внутри `3rdparty/blobs`; VBT
отслеживается вместе с исходниками платы.
