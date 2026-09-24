#include "ce_coeff.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xtime_l.h"
#include "sleep.h"
#ifndef CE_COEFF_BASE
#define CE_COEFF_BASE XPAR_PARAM_M_AXI_BASEADDR
#endif
#define REG_ID 0x00u
#define REG_CMD 0x04u
#define REG_STATUS 0x08u
#define REG_CHANNEL 0x10u
#define REG_INDEX 0x14u
#define REG_RE 0x18u
#define REG_IM 0x1cu
#define REG_PUSH 0x20u
#define REG_COUNT0 0x24u
#define REG_COUNT1 0x28u
#define REG_CRC0 0x2cu
#define REG_CRC1 0x30u
#define REG_EXPECT0 0x34u
#define REG_EXPECT1 0x38u
#define ST_BUSY 1u
#define ST_READY 2u
#define ST_SEALED 4u
#define ST_RUNNING 8u
#define ST_ERROR 0x20u
#define ST_VALID 0x40u
static uint32_t last_hw_error;
uint32_t ce_coeff_last_hw_error(void) { return last_hw_error; }
static uint32_t rd(unsigned off) { return Xil_In32(CE_COEFF_BASE+off); }
static void wr(unsigned off,uint32_t value)
{
    Xil_Out32(CE_COEFF_BASE+off,value);
    /* Complete the device write before polling BUSY or staging another word. */
    DATA_SYNC;
}
uint32_t ce_coeff_crc_word(uint32_t crc,uint32_t word)
{
    unsigned b,k;
    for(b=0;b<4;b++) {
        crc ^= word & 255u; word >>= 8;
        for(k=0;k<8;k++) crc=(crc>>1)^((crc&1u)?0xedb88320u:0u);
    }
    return crc;
}
int ce_coeff_parse_hex(const char *line,uint32_t *value)
{
    unsigned n; uint32_t v=0;
    if(!line || !value) return CE_BAD_FORMAT;
    for(n=0;n<5;n++) {
        unsigned d;char c=line[n];
        if(c>='0' && c<='9') d=(unsigned)(c-'0');
        else if(c>='a' && c<='f') d=(unsigned)(c-'a'+10);
        else if(c>='A' && c<='F') d=(unsigned)(c-'A'+10);
        else return CE_BAD_FORMAT;
        v=(v<<4)|d;
    }
    if(line[5]!='\0' || v>0x3ffffu) return CE_BAD_FORMAT;
    *value=v;return CE_OK;
}
static int wait_idle(uint32_t ms,int check_error)
{
    XTime start,now;XTime_GetTime(&start);
    do {
        uint32_t status=rd(REG_STATUS);
        if(!(status&ST_BUSY)) {
            if(check_error && (status&ST_ERROR)) {last_hw_error=rd(0x0cu);return CE_HW_ERROR;}
            return CE_OK;
        }
        XTime_GetTime(&now);
        if(now-start >= ((uint64_t)COUNTS_PER_SECOND*ms)/1000u) return CE_TIMEOUT;
        usleep(1);
    } while(1);
}
static int command(uint32_t op,uint32_t ms)
{
    int rc=wait_idle(ms,0);if(rc) return rc;
    wr(REG_CMD,op);return wait_idle(ms,1);
}
int ce_coeff_load(const CeCoeffImage *image,uint32_t timeout_ms)
{
    uint32_t crc[2]={0xffffffffu,0xffffffffu};unsigned ch,k;int rc;
    last_hw_error=0;
    if(!image || !timeout_ms) return CE_BAD_FORMAT;
    /* Validate the complete image before issuing BEGIN (before muting). */
    for(ch=0;ch<1;ch++) for(k=0;k<CE_COEFF_POINTS;k++) {
        uint32_t re=image->file[ch*2][k],im=image->file[ch*2+1][k];
        if((re|im)>0x3ffffu) return CE_BAD_FORMAT;
        crc[ch]=ce_coeff_crc_word(ce_coeff_crc_word(crc[ch],re),im);
    }
    crc[0]=~crc[0];crc[1]=~crc[1];
    /* Only call with the NEW bitstream installed: old designs have no slave
     * at this address, and a CPU MMIO timeout cannot rescue a hung AXI bus. */
    if(rd(REG_ID)!=0x43465231u) return CE_BAD_ID;
    rc=command(1,timeout_ms);if(rc) return rc;
    if(!(rd(REG_STATUS)&ST_READY)) return CE_HW_ERROR;
    for(ch=0;ch<1;ch++) {
        wr(REG_CHANNEL,ch);wr(REG_INDEX,0);
        for(k=0;k<CE_COEFF_POINTS;k++) {
            wr(REG_RE,image->file[ch*2][k]);wr(REG_IM,image->file[ch*2+1][k]);
            wr(REG_PUSH,1);
            rc=wait_idle(timeout_ms,1);if(rc) return rc;
        }
    }
    if(rd(REG_COUNT0)!=300 ||
       rd(REG_CRC0)!=crc[0]) return CE_HW_ERROR;
    wr(REG_EXPECT0,crc[0]);wr(REG_EXPECT1,crc[1]);
    rc=command(3,timeout_ms);if(rc) return rc;
    if((rd(REG_STATUS)&(ST_SEALED|ST_VALID))!=(ST_SEALED|ST_VALID)) return CE_HW_ERROR;
    rc=command(4,timeout_ms);if(rc) return rc;
    return (rd(REG_STATUS)&ST_RUNNING) ? CE_OK : CE_HW_ERROR;
}
