/* SPDX-License-Identifier: GPL-2.0-only */

Scope (\_SB)
{
	Device (UBTC)
	{
		Name (_HID, EisaId ("USBC000"))
		Name (_CID, EisaId ("PNP0CA0"))
		Name (_UID, Zero)
		Name (_DDN, "USB Type C")

		Mutex (UCSM, 0)

		External (\UCBA, IntObj)
		External (\_SB.UBTC.VERS, FieldUnitObj)
		External (\_SB.UBTC.CCI, FieldUnitObj)
		External (\_SB.UBTC.CTRL, FieldUnitObj)
		External (\_SB.UBTC.MSGI, FieldUnitObj)
		External (\_SB.UBTC.MSGO, FieldUnitObj)

		Name (CRS, ResourceTemplate ()
		{
			Memory32Fixed (ReadWrite,
				0x00000000,
				0x00001000,
				_Y01)
		})

		Method (_CRS, 0, Serialized)
		{
			CreateDWordField (CRS, \_SB.UBTC._Y01._BAS, CBAS)
			CBAS = \UCBA
			Return (CRS)
		}

		Method (_STA, 0, NotSerialized)
		{
			Return (0x0f)
		}

		Device (CR01)
		{
			Name (_ADR, Zero)
			Method (_PLD, 0, Serialized)
			{
				Name (PCKG, Package (1)
				{
					Buffer (0x14) {}
				})
				CreateField (DerefOf (PCKG [0]), 0, 7, REV)
				REV = 1
				CreateField (DerefOf (PCKG [0]), 64, 1, VISI)
				VISI = 1
				CreateField (DerefOf (PCKG [0]), 87, 8, GPOS)
				GPOS = 3
				Return (PCKG)
			}
		}

		Method (_DSM, 4, Serialized)
		{
			If (Arg0 == ToUUID ("6f8398c2-7ca4-11e4-ad36-631042b5008f"))
			{
				Switch (ToInteger (Arg2))
				{
					Case (0)
					{
						Acquire (UCSM, 0xffff)
						\_SB.UBTC.VERS = \_SB.PCI0.LPCB.EC0.VERS
						Release (UCSM)
						Return (Buffer (1) { 0x07 })
					}
					Case (1)
					{
						Acquire (UCSM, 0xffff)
						\_SB.PCI0.LPCB.EC0.MSGO = \_SB.UBTC.MSGO
						\_SB.PCI0.LPCB.EC0.CTRL = \_SB.UBTC.CTRL
						\_SB.PCI0.LPCB.EC0.CMD0 = 0x80
						\_SB.PCI0.LPCB.EC0.CMDB = 0xe0
						Release (UCSM)
					}
					Case (2)
					{
						Acquire (UCSM, 0xffff)
						\_SB.UBTC.MSGI = \_SB.PCI0.LPCB.EC0.MSGI
						\_SB.UBTC.CCI = \_SB.PCI0.LPCB.EC0.CCI
						Release (UCSM)
					}
				}
			}
			Return (Buffer (1) { 0x00 })
		}
	}
}
