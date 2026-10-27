/* SPDX-License-Identifier: GPL-2.0-only */

#include <console/console.h>
#include <gpio.h>
#include <soc/ramstage.h>

#include "gpio.h"

void mainboard_silicon_init_params(FSP_SIL_UPD *params)
{
	const int dgpu_pwok = gpio_get(GPP_G3);

	/* Configure board pads before FSP SiliconInit(). */
	gpio_configure_pads(gpio_table, ARRAY_SIZE(gpio_table));

	printk(BIOS_INFO, "TM1703: dGPU PWOK (GPP_G3) = %d\n", dgpu_pwok);
	if (!dgpu_pwok)
		printk(BIOS_ERR,
		       "TM1703: dGPU PWOK is low; releasing reset as OEM does\n");

	/* APDT is satisfied by the time spent in FSP-M and raminit. */
	gpio_set(GPP_G1, 1);
}
