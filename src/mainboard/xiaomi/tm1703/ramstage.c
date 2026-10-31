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
	/* Configure board pads before FSP SiliconInit(). */
	mainboard_configure_gpios();

	/* APDT is satisfied by the time spent in FSP-M and raminit. */
	gpio_set(GPP_G1, 1);

	/* Allow NVMe SSD controller sufficient time to power up and exit Detect state. */
	params->PcieDetectTimeoutMs = 1000;
}

static void mainboard_fill_ssdt(const struct device *dev)
{
	const size_t ucsi_alloc_len = 0x1000;
	const size_t ucsi_reg_len = 0x30;
	void *region_ptr = cbmem_add(CBMEM_ID_ACPI_UCSI, ucsi_alloc_len);

	if (!region_ptr) {
		printk(BIOS_ERR, "TM1703: Failed to allocate CBMEM for UCSI\n");
		return;
	}
	memset(region_ptr, 0, ucsi_alloc_len);
	*(uint16_t *)region_ptr = 0x0100; /* UCSI version 1.0 */

	struct opregion opreg = {
		.name = "USBC",
		.regionspace = SYSTEMMEMORY,
		.regionoffset = (uintptr_t)region_ptr,
		.regionlen = ucsi_reg_len,
	};
	static struct fieldlist ucsi_region_fields[] = {
		FIELDLIST_NAMESTR("VERS", 16),
		FIELDLIST_OFFSET(4),
		FIELDLIST_NAMESTR("CCI", 32),
		FIELDLIST_NAMESTR("CTRL", 64),
		FIELDLIST_NAMESTR("MSGI", 128),
		FIELDLIST_NAMESTR("MSGO", 128),
	};

	acpigen_write_scope("\\");
	acpigen_write_name_dword("UCBA", (uintptr_t)region_ptr);
	acpigen_write_scope_end();

	acpigen_write_scope("\\_SB.UBTC");
	acpigen_write_opregion(&opreg);
	acpigen_write_field(opreg.name, ucsi_region_fields,
			    ARRAY_SIZE(ucsi_region_fields),
			    FIELD_BYTEACC | FIELD_LOCK | FIELD_PRESERVE);
	acpigen_write_scope_end();

	printk(BIOS_DEBUG, "TM1703: UCSI mailbox at %p\n", region_ptr);
}

static void mainboard_enable(struct device *dev)
{
	dev->ops->acpi_fill_ssdt = mainboard_fill_ssdt;
}

struct chip_operations mainboard_ops = {
	.enable_dev = mainboard_enable,
};
