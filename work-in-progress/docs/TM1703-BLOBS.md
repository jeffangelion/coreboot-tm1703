# TM1703: локальное получение закрытых компонентов

IFD, Intel ME, EC и VBT являются закрытыми компонентами заводской прошивки.
Они не добавляются в Git и должны быть извлечены пользователем из собственного
16-MiB дампа SPI-флешки TM1703.

## Подготовка

Все команды выполняются из корня дерева coreboot. Укажите путь к своему дампу:

```sh
tm1703_dump=/path/to/tm1703-16mib.bin
test "$(stat -c %s "$tm1703_dump")" -eq 16777216
tm1703_blob_dir=3rdparty/blobs/mainboard/xiaomi/tm1703
mkdir -p "$tm1703_blob_dir"
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

Извлечение:

```sh
dd if="$tm1703_dump" of="$tm1703_blob_dir/descriptor.bin" \
  bs=1 skip=$((0x000000)) count=$((0x001000)) status=none
dd if="$tm1703_dump" of="$tm1703_blob_dir/me.bin" \
  bs=1 skip=$((0x001000)) count=$((0x8ff000)) status=none
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

В проверенном заводском образе используемый VBT начинается с `$VBT` по
смещению `0xf9888c` и имеет размер 4441 байт. Сначала убедитесь, что сигнатура
найдена в ожидаемом месте:

```sh
grep -obUa '\$VBT' "$tm1703_dump"
dd if="$tm1703_dump" of="$tm1703_blob_dir/vbt.bin" \
  bs=1 skip=$((0xf9888c)) count=4441 status=none
sha256sum "$tm1703_blob_dir/vbt.bin"
```

Ожидаемый SHA-256:

```text
7aebcc9be9956903ff57e80c18cbff99866975d3e41c0debbe5807a9473eb0f5
```

Дополнительная проверка структуры:

```sh
intel_vbt_decode --file "$tm1703_blob_dir/vbt.bin"
```

Если сигнатур несколько, смещение или размер отличаются, не выбирайте VBT
автоматически: сначала сравните панель и результат декодирования с live VBT
своей работающей системы.

## Проверка перед сборкой

```sh
stat -c '%s %n' \
  "$tm1703_blob_dir/descriptor.bin" \
  "$tm1703_blob_dir/me.bin" \
  "$tm1703_blob_dir/ec.bin" \
  "$tm1703_blob_dir/vbt.bin"
sha256sum \
  "$tm1703_blob_dir/descriptor.bin" \
  "$tm1703_blob_dir/me.bin" \
  "$tm1703_blob_dir/ec.bin" \
  "$tm1703_blob_dir/vbt.bin"
```

Ожидаемые размеры: 4096, 9433088, 262144 и 4441 байт соответственно. Файлы
остаются локальными и незатреканными внутри `3rdparty/blobs`.
