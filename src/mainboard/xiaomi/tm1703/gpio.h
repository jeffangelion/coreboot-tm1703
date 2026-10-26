/* SPDX-License-Identifier: GPL-2.0-only */

#ifndef MAINBOARD_GPIO_H
#define MAINBOARD_GPIO_H

#include <soc/gpio.h>

#ifndef __ACPI__

/*
 * These pins are configured before FSP SiliconInit().  Their native functions
 * and terminations were recovered from ProgramGPIOPei and verified against
 * the OEM GPIO register dump.
 *
 * Panel power and backlight are controlled by the EC, not by PCH GPIO.
 */
static const struct pad_config gpio_table[] = {
	/* DDPB_HPD0 / HDMI1 */
	PAD_CFG_NF(GPP_E13, NONE, DEEP, NF1),
	/* eDP panel hot-plug detect */
	PAD_CFG_NF(GPP_E17, NONE, DEEP, NF1),
	/* DDPB auxiliary channel */
	PAD_CFG_NF(GPP_E18, NONE, DEEP, NF1),
	PAD_CFG_NF(GPP_E19, DN_20K, DEEP, NF1),
};

#endif

#endif
