/* SPDX-License-Identifier: GPL-2.0-only */

#include <stdint.h>
#include <string.h>

#include "spd.h"

void mainboard_fill_dq_map_data(void *dq_map_ptr)
{
	static const uint8_t dq_map[2][12] = {
		{ 0x0f, 0xf0, 0x00, 0xf0, 0x0f, 0xf0,
		  0x0f, 0x00, 0xff, 0x00, 0xff, 0x00 },
		{ 0x0f, 0xf0, 0x00, 0xf0, 0x0f, 0xf0,
		  0x0f, 0x00, 0xff, 0x00, 0xff, 0x00 },
	};

	memcpy(dq_map_ptr, dq_map, sizeof(dq_map));
}

void mainboard_fill_dqs_map_data(void *dqs_map_ptr)
{
	/* OEM PEI uses identity DQS mapping for both channels. */
	static const uint8_t dqs_map[2][8] = {
		{ 0, 1, 2, 3, 4, 5, 6, 7 },
		{ 0, 1, 2, 3, 4, 5, 6, 7 },
	};

	memcpy(dqs_map_ptr, dqs_map, sizeof(dqs_map));
}

void mainboard_fill_rcomp_res_data(void *rcomp_ptr)
{
	static const uint16_t rcomp_resistor[3] = { 200, 81, 162 };

	memcpy(rcomp_ptr, rcomp_resistor, sizeof(rcomp_resistor));
}

void mainboard_fill_rcomp_strength_data(void *rcomp_strength_ptr)
{
	static const uint16_t rcomp_target[5] = { 100, 40, 40, 23, 40 };

	memcpy(rcomp_strength_ptr, rcomp_target, sizeof(rcomp_target));
}
