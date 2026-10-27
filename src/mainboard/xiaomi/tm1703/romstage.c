/* SPDX-License-Identifier: GPL-2.0-only */

#include <console/console.h>
#include <device/dram/common.h>
#include <gpio.h>
#include <lib.h>
#include <soc/gpio.h>
#include <soc/romstage.h>
#include <spd_bin.h>

#include "spd/spd.h"

void mainboard_memory_init_params(FSPM_UPD *mupd)
{
	FSP_M_CONFIG *const mem_cfg = &mupd->FspmConfig;
	const uint8_t *spd;
	const unsigned int spd_index = gpio_get(GPP_D0) |
		(gpio_get(GPP_D1) << 1) |
		(gpio_get(GPP_D2) << 2) |
		(gpio_get(GPP_D3) << 3);

	printk(BIOS_INFO, "TM1703 memory strap index: %u\n", spd_index);

	mainboard_fill_dq_map_data(&mem_cfg->DqByteMapCh0);
	mainboard_fill_dqs_map_data(&mem_cfg->DqsMapCpu2DramCh0);
	mainboard_fill_rcomp_res_data(&mem_cfg->RcompResistor);
	mainboard_fill_rcomp_strength_data(&mem_cfg->RcompTarget);

	mem_cfg->DqPinsInterleaved = 1;
	mem_cfg->CaVrefConfig = 0;
	mem_cfg->MemorySpdDataLen = CONFIG_DIMM_SPD_SIZE;
	mem_cfg->MemorySpdPtr00 = spd_cbfs_map(spd_index);
	if (!mem_cfg->MemorySpdPtr00)
		die("TM1703 SPD not found\n");

	spd = (const uint8_t *)(uintptr_t)mem_cfg->MemorySpdPtr00;
	printk(BIOS_INFO, "TM1703 SPD: ptr=%p len=%u\n", spd,
	       mem_cfg->MemorySpdDataLen);
	printk(BIOS_INFO, "TM1703 SPD CRC: base=%04x/%04x module=%04x/%04x\n",
	       ddr_crc16(spd, 126), spd[126] | (spd[127] << 8),
	       ddr_crc16(spd + 128, 126), spd[254] | (spd[255] << 8));
}
