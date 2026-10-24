/* SPDX-License-Identifier: GPL-2.0-only */

#include <console/console.h>
#include <gpio.h>
#include <soc/gpio.h>
#include <soc/romstage.h>
#include <spd_bin.h>

#include "spd/spd.h"

void mainboard_memory_init_params(FSPM_UPD *mupd)
{
	FSP_M_CONFIG *const mem_cfg = &mupd->FspmConfig;
	const unsigned int spd_index = gpio_get(GPP_D0) |
		(gpio_get(GPP_D1) << 1) |
		(gpio_get(GPP_D2) << 2) |
		(gpio_get(GPP_D3) << 3);

	printk(BIOS_INFO, "TM1703 memory strap index: %u\n", spd_index);

	mainboard_fill_dq_map_data(&mem_cfg->DqByteMapCh0);
	mainboard_fill_dqs_map_data(&mem_cfg->DqsMapCpu2DramCh0);

	mem_cfg->DqPinsInterleaved = 0;
	mem_cfg->MemorySpdDataLen = CONFIG_DIMM_SPD_SIZE;
	mem_cfg->MemorySpdPtr00 = spd_cbfs_map(spd_index);
	if (!mem_cfg->MemorySpdPtr00)
		die("TM1703 SPD not found\n");
}
