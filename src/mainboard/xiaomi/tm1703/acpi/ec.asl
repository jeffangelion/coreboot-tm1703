/* SPDX-License-Identifier: GPL-2.0-only */

/* Minimal EC and battery model based on the TM1703 OEM SSDT. */

Scope (\_SB.PCI0.LPCB)
{
	Device (EC0)
	{
		Name (_HID, EisaId ("PNP0C09"))
		Name (_GPE, 0x4f)

		Name (_CRS, ResourceTemplate ()
		{
			IO (Decode16, 0x62, 0x62, 0, 1)
			IO (Decode16, 0x66, 0x66, 0, 1)
		})

		OperationRegion (ECMB, SystemMemory, 0xfe802000, 0x200)
		Field (ECMB, ByteAcc, Lock, Preserve)
		{
			Offset (0x02),
			MACS, 1,
			Offset (0x08),
			NB0S, 8
		}

		OperationRegion (BATR, SystemMemory, 0xfe802080, 0x80)
		Field (BATR, ByteAcc, Lock, Preserve)
		{
			BSRC, 16,
			BSFC, 16,
			BSPE, 16,
			BSAC, 16,
			BSVO, 16,
			, 15,
			BSCM, 1,
			BSCU, 16,
			BSTV, 16,
			BSDC, 16,
			BSDV, 16,
			BSSN, 16,
			Offset (0x40),
			BSMN, 128,
			BSDN, 256,
			BSCH, 128
		}

		Method (_STA, 0, NotSerialized)
		{
			Return (0x0f)
		}

		Device (ADP1)
		{
			Name (_HID, "ACPI0003")
			Name (ACST, One)

			Method (_PSR, 0, NotSerialized)
			{
				Return (MACS)
			}

			Method (_STA, 0, NotSerialized)
			{
				Return (0x0f)
			}
		}

		Device (BAT0)
		{
			Name (_HID, EisaId ("PNP0C0A"))
			Name (_UID, Zero)
			Name (BSTP, Package () { Zero, Zero, Zero, Zero })

			Method (_STA, 0, NotSerialized)
			{
				If (NB0S & One)
				{
					Return (0x1f)
				}

				Return (0x0f)
			}

			Method (_BIF, 0, NotSerialized)
			{
				Return (Package ()
				{
					Zero,
					BSDC,
					BSFC,
					One,
					BSDV,
					BSPE,
					BSPE,
					One,
					One,
					"",
					"TM1703",
					"R13B02W",
					"CPT-COS",
					"Xiaomi"
				})
			}

			Method (_BST, 0, NotSerialized)
			{
				Local0 = Zero
				If (NB0S & 0x02)
				{
					Local0 = 0x02
				}
				If (NB0S & 0x04)
				{
					Local0 = One
				}
				If (NB0S & 0x10)
				{
					Local0 |= 0x04
				}

				BSTP [Zero] = Local0
				BSTP [One] = BSAC
				BSTP [0x02] = BSRC
				BSTP [0x03] = BSVO
				Return (BSTP)
			}
		}
	}
}
