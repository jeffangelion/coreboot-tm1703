/* SPDX-License-Identifier: GPL-2.0-only */

#include <console/console.h>
#include <device/pci_ops.h>
#include <intelblocks/cse.h>
#include <soc/pci_devs.h>

#include "me_status.h"

void tm1703_log_me_hfsts(const char *point)
{
	printk(BIOS_INFO,
	       "TM1703 f25 ME HFSTS %s: %08x %08x %08x %08x %08x %08x\n",
	       point,
	       pci_read_config32(PCH_DEV_CSE, PCI_ME_HFSTS1),
	       pci_read_config32(PCH_DEV_CSE, PCI_ME_HFSTS2),
	       pci_read_config32(PCH_DEV_CSE, PCI_ME_HFSTS3),
	       pci_read_config32(PCH_DEV_CSE, PCI_ME_HFSTS4),
	       pci_read_config32(PCH_DEV_CSE, PCI_ME_HFSTS5),
	       pci_read_config32(PCH_DEV_CSE, PCI_ME_HFSTS6));
}
