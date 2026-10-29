/* SPDX-License-Identifier: GPL-2.0-only */

/* Minimal EC, battery and UCSI model based on the TM1703 OEM SSDT. */

External (\_SB.UBTC, DeviceObj)
External (\_SB.UBTC.UCSM, MutexObj)
External (\_SB.UBTC.MSGI, FieldUnitObj)
External (\_SB.UBTC.CCI, FieldUnitObj)

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

		Name (\ECOK, Zero)

		OperationRegion (RAM, EmbeddedControl, Zero, 0xff)
		Field (RAM, ByteAcc, Lock, Preserve)
		{
			CMDB, 8,
			Offset (0x06),
			CMD2, 8,
			CMD1, 8,
			CMD0, 8,
			Offset (0x10),
			EQEN, 1,
			ETEE, 1,
			Offset (0x76),
			ECSS, 4,
			EOSS, 4,
			Offset (0x92),
			ETAF, 8
		}

		Method (TINI, 0, NotSerialized)
		{
			If (\ECOK)
			{
				ETAF = Zero
				ETEE = One
			}
		}

		Method (_REG, 2, NotSerialized)
		{
			If (Arg0 == 0x03)
			{
				\ECOK = Arg1
				If (Arg1 == One)
				{
					EQEN = One
					TINI ()
					EOSS = 0x05
				}
				Else
				{
					ETEE = Zero
				}
			}
		}

		OperationRegion (USMB, SystemMemory, 0xfe801010, 0x30)
		Field (USMB, ByteAcc, Lock, Preserve)
		{
			VERS, 16,
			Offset (0x04),
			CCI,  32,
			CTRL, 64,
			MSGI, 128,
			MSGO, 128
		}

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

		Method (_Q79, 0, NotSerialized)
		{
			Acquire (\_SB.UBTC.UCSM, 0xffff)
			\_SB.UBTC.MSGI = MSGI
			\_SB.UBTC.CCI = CCI
			Release (\_SB.UBTC.UCSM)
			Notify (\_SB.UBTC, 0x80)
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
