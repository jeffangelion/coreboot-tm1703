## SPDX-License-Identifier: GPL-2.0-only

subdirs-y += spd

CPPFLAGS_common += -I$(src)/mainboard/$(MAINBOARDDIR)/include

bootblock-y += bootblock.c
bootblock-y += gpio_early.c

romstage-y += romstage.c
romstage-y += spd/spd_util.c

ramstage-y += gpio.c
ramstage-y += ramstage.c
ramstage-y += hda_verb.c

ramstage-$(CONFIG_MAINBOARD_USE_LIBGFXINIT) += gma-mainboard.ads
# ramstage-$(CONFIG_DRIVERS_OPTION_CFR_ENABLED) += cfr.c

# NVIDIA GeForce MX150 (GP108M) VBIOS for ACPI _ROM method
cbfs-files-y += pci10de,1d12.rom
pci10de,1d12.rom-file := 3rdparty/blobs/mainboard/$(MAINBOARDDIR)/pci10de,1d12.rom
pci10de,1d12.rom-type := optionrom

# The TM1703 EC is stored outside the IFD EC region, at 0x900000.
# Add it after the descriptor and ME have been stitched.
TM1703_EC_FW := 3rdparty/blobs/mainboard/$(MAINBOARDDIR)/ec.bin

PHONY += add_tm1703_ec

add_tm1703_ec: add_intel_firmware $(TM1703_EC_FW)
	printf "    DD         TM1703 EC -> coreboot.pre\n"
	dd if=$(TM1703_EC_FW) of=$(obj)/coreboot.pre bs=1 seek=9437184 conv=notrunc status=none

$(obj)/coreboot.rom: add_tm1703_ec
$(obj)/coreboot.rom: payloads/coreinfo/build/coreinfo.elf
