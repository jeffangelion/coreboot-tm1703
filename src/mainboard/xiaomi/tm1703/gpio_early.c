/* SPDX-License-Identifier: GPL-2.0-only */

#include <mainboard/gpio.h>
#include <soc/gpio.h>

/* Memory-configuration straps, GPP_D3:D0 with D0 as the least significant bit. */
static const struct pad_config early_gpio_table[] = {
	PAD_CFG_GPI(GPP_D0, NONE, DEEP),
	PAD_CFG_GPI(GPP_D1, NONE, DEEP),
	PAD_CFG_GPI(GPP_D2, NONE, DEEP),
	PAD_CFG_GPI(GPP_D3, NONE, DEEP),
};

void mainboard_configure_early_gpios(void)
{
	gpio_configure_pads(early_gpio_table, ARRAY_SIZE(early_gpio_table));
}
