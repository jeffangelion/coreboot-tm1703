/* SPDX-License-Identifier: GPL-2.0-only */

#include <acpi/acpi.h>
#include <acpi/acpigen.h>
#include <cbmem.h>
#include <console/console.h>
#include <device/device.h>
#include <gpio.h>
#include <mainboard/gpio.h>
#include <soc/ramstage.h>
#include <string.h>

void mainboard_silicon_init_params(FSP_SIL_UPD *params)
{
	const int dgpu_pwok = gpio_get(GPP_G3);

	/* Configure board pads before FSP SiliconInit(). */
	mainboard_configure_gpios();

	printk(BIOS_INFO, "TM1703: dGPU PWOK (GPP_G3) = %d\n", dgpu_pwok);
	if (!dgpu_pwok)
		printk(BIOS_ERR,
		       "TM1703: dGPU PWOK is low; releasing reset as OEM does\n");

	/* APDT is satisfied by the time spent in FSP-M and raminit. */
	gpio_set(GPP_G1, 1);
}

static void mainboard_fill_ssdt(const struct device *dev)
{
	const size_t ucsi_alloc_len = 0x1000;
	void *region_ptr = cbmem_add(CBMEM_ID_ACPI_UCSI, ucsi_alloc_len);

	if (!region_ptr) {
		printk(BIOS_ERR, "TM1703: Failed to allocate CBMEM for UCSI\n");
		return;
	}
	memset(region_ptr, 0, ucsi_alloc_len);

	acpigen_write_scope("\\");
	acpigen_write_name_dword("UCBA", (uintptr_t)region_ptr);
	acpigen_write_scope_end();

	printk(BIOS_INFO, "TM1703: UCSI mailbox at %p, emitted \\UCBA\n", region_ptr);
}

static void mainboard_enable(struct device *dev)
{
	dev->ops->acpi_fill_ssdt = mainboard_fill_ssdt;
}

struct chip_operations mainboard_ops = {
	.enable_dev = mainboard_enable,
};

