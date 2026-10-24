## SPDX-License-Identifier: GPL-2.0-only

subdirs-y += spd

CPPFLAGS_common += -I$(src)/mainboard/$(MAINBOARDDIR)/include

bootblock-y += bootblock.c
bootblock-y += gpio_early.c

romstage-y += romstage.c
romstage-y += spd/spd_util.c

ramstage-y += ramstage.c
ramstage-y += hda_verb.c

ramstage-$(CONFIG_MAINBOARD_USE_LIBGFXINIT) += gma-mainboard.ads
# ramstage-$(CONFIG_DRIVERS_OPTION_CFR_ENABLED) += cfr.c

# The TM1703 EC is stored outside the IFD EC region, at 0x900000.
# Add it after the descriptor and ME have been stitched.
TM1703_EC_FW := $(src)/mainboard/xiaomi/tm1703/ec_0W.02ML.01.16.bin

PHONY += add_tm1703_ec

add_tm1703_ec: add_intel_firmware $(TM1703_EC_FW)
	printf "    DD         TM1703 EC -> coreboot.pre\n"
	dd if=$(TM1703_EC_FW) of=$(obj)/coreboot.pre bs=1 seek=9437184 conv=notrunc status=none

$(obj)/coreboot.rom: add_tm1703_ec
