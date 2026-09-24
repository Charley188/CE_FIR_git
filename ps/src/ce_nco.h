#ifndef CE_NCO_H
#define CE_NCO_H
#include "xil_io.h"
#include "xil_printf.h"
#include "parameters.h"
/* RFDC v2.6 / rfdc_v12_0 xrfdc_hw.h: ADC/DAC tile0 DRP 0x16000/0x6000,
 * physical block stride 0x400, NCO_UPDT 0x08c, event mask 7.
 * Use 16-bit access like XRFdc_ClrSetReg; preserve other bits.
 * Call after RFDC startup and repeat after any RFDC restart/reset. */
static int ce_nco_vio_init(void)
{
    static const u32 offsets[] = {0x1608cU, 0x1648cU, 0x1688cU,
                                  0x16c8cU, 0x608cU, 0x688cU};
    unsigned int i;
    for (i = 0; i < sizeof(offsets)/sizeof(offsets[0]); ++i) {
        UINTPTR addr = (UINTPTR)USP_RF_DATA_CONV_BASEADDR + offsets[i];
        u16 mode = 2U; /* Both generated NCO FSMs issue tile update at DRP 0x72e. */
        u16 value = Xil_In16(addr);
        Xil_Out16(addr, (u16)((value & (u16)~7U) | mode));
        if ((Xil_In16(addr) & 7U) != mode) {
            xil_printf("NCO event source readback failed at offset 0x%lx\r\n",
                       (unsigned long)offsets[i]);
            return -1;
        }
    }
    xil_printf("Fine NCO VIO ready: ADC/DAC Tile events.\r\n");
    return 0;
}
#endif
