/* SPDX-License-Identifier: GPL-2.0-only */

#include <bootblock_common.h>
#include <intelblocks/lpc_lib.h>
#include <mainboard/gpio.h>

void bootblock_mainboard_early_init(void)
{
	/* Open 64 KiB MMIO window at 0xfe800000 on LPC for EC registers and UCSI */
	lpc_open_mmio_window(0xfe800000, 0x10000);
	mainboard_configure_early_gpios();
}
