/* SPDX-License-Identifier: GPL-2.0-only */

/* Minimal EC, battery and UCSI model based on the TM1703 OEM SSDT. */

External (\_SB.UBTC, DeviceObj)
External (\_SB.UBTC.UCSM, MutexObj)
External (\_SB.UBTC.MSGI, FieldUnitObj)
External (\_SB.UBTC.CCI, FieldUnitObj)
External (\_SB.LID0, DeviceObj)
External (\_SB.SLPB, DeviceObj)
External (\_SB.BTID, IntObj)
External (\_SB.WMID, DeviceObj)
External (\_SB.PCI0.GFX0.INCB, MethodObj)
External (\_SB.PCI0.GFX0.DECB, MethodObj)

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
			Offset (0x58),
			WHKE, 8,
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
			, 1,
			MLID, 1,
			, 3,
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

		Method (PTS, 1, NotSerialized)
		{
			ECSS = Arg0
		}

		Method (WAK, 1, NotSerialized)
		{
			EQEN = One
			EOSS = Arg0
			TINI ()
			Notify (BAT0, 0x81)
			If (CondRefOf (\_SB.LID0))
			{
				Notify (\_SB.LID0, 0x80)
			}
			If (CondRefOf (\_SB.SLPB))
			{
				Notify (\_SB.SLPB, 0x02)
			}
		}

		/* Brightness hotkeys */
		Method (_Q1C, 0, NotSerialized)
		{
			If (CondRefOf (\_SB.PCI0.GFX0.INCB))
			{
				\_SB.PCI0.GFX0.INCB ()
			}
		}

		Method (_Q1D, 0, NotSerialized)
		{
			If (CondRefOf (\_SB.PCI0.GFX0.DECB))
			{
				\_SB.PCI0.GFX0.DECB ()
			}
		}

		/* Fn hotkeys / keyboard backlight */
		Method (_Q2C, 0, NotSerialized)
		{
			If (\ECOK)
			{
				Local0 = WHKE
			}
			Else
			{
				Local0 = Zero
			}

			If (Local0)
			{
				\_SB.BTID = Local0
				If (CondRefOf (\_SB.WMID))
				{
					Notify (\_SB.WMID, 0xD2)
				}
			}
		}

		Method (_Q65, 0, NotSerialized)
		{
			\_SB.BTID = 0x08
			If (CondRefOf (\_SB.WMID))
			{
				Notify (\_SB.WMID, 0xD2)
			}
		}

		Method (_Q69, 0, NotSerialized)
		{
			\_SB.BTID = 0x07
			If (CondRefOf (\_SB.WMID))
			{
				Notify (\_SB.WMID, 0xD2)
			}
		}

		/* Battery status & info notifications */
		Method (_Q40, 0, NotSerialized)
		{
			Notify (BAT0, 0x81)
		}

		Method (_Q41, 0, NotSerialized)
		{
			Notify (BAT0, 0x81)
		}

		Method (_Q48, 0, NotSerialized)
		{
			Notify (BAT0, 0x80)
		}

		Method (_Q4C, 0, NotSerialized)
		{
			Notify (BAT0, 0x80)
		}

		/* AC status notifications */
		Method (_Q50, 0, NotSerialized)
		{
			Notify (ADP1, 0x80)
			Notify (BAT0, 0x80)
		}

		Method (_Q51, 0, NotSerialized)
		{
			Notify (ADP1, 0x80)
			Notify (BAT0, 0x80)
		}

		/* Lid status notifications */
		Method (_Q52, 0, NotSerialized)
		{
			If (CondRefOf (\_SB.LID0))
			{
				Notify (\_SB.LID0, 0x80)
			}
		}

		Method (_Q53, 0, NotSerialized)
		{
			If (CondRefOf (\_SB.LID0))
			{
				Notify (\_SB.LID0, 0x80)
			}
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
			Name (BIFP, Package ()
			{
				Zero,
				Zero,
				Zero,
				One,
				Zero,
				Zero,
				Zero,
				One,
				One,
				"R13B02W",
				"TM1703",
				"LION",
				"Xiaomi"
			})

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
				Local0 = BSCM
				BIFP [Zero] = (Local0 ^ One)
				If (Local0)
				{
					Local1 = BSDC * 10
					Local2 = BSFC * 10
				}
				Else
				{
					Local1 = BSDC
					Local2 = BSFC
				}

				BIFP [One] = Local1
				BIFP [0x02] = Local2
				BIFP [0x04] = BSDV

				/* Warning and low capacity thresholds */
				Local6 = Local2 / 100
				BIFP [0x05] = Local6 * 7
				BIFP [0x06] = (Local6 * 11) / 2

				Return (BIFP)
			}

			Method (_BST, 0, NotSerialized)
			{
				If (NB0S & 0x02)
				{
					Local0 = 0x02
					If (NB0S & 0x20)
					{
						Local0 = Zero
					}
				}
				ElseIf (NB0S & 0x04)
				{
					Local0 = One
				}
				Else
				{
					Local0 = Zero
				}

				If (NB0S & 0x10)
				{
					Local0 |= 0x04
				}

				If (NB0S & One)
				{
					Local1 = BSAC
					Local2 = BSRC
					If (MACS)
					{
						If (NB0S & 0x20)
						{
							Local2 = BSFC
						}
					}

					If (BSCM)
					{
						Local2 *= 10
					}

					Local3 = BSVO
					If (Local1 >= 0x8000)
					{
						If (Local0 & One)
						{
							Local1 = 0x10000 - Local1
						}
						Else
						{
							Local1 = Zero
						}
					}
					ElseIf ((Local0 & 0x02) == Zero)
					{
						Local1 = Zero
					}

					If (BSCM)
					{
						Local1 = (Local1 * Local3) / 1000
					}
				}
				Else
				{
					Local0 = Zero
					Local1 = 0xffffffff
					Local2 = 0xffffffff
					Local3 = 0xffffffff
				}

				BSTP [Zero] = Local0
				BSTP [One] = Local1
				BSTP [0x02] = Local2
				BSTP [0x03] = Local3
				Return (BSTP)
			}
		}
	}
}
