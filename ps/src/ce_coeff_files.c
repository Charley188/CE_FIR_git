/*
 * Vitis Classic managed build runs from Debug/ or Release/.
 * Replace the two MEM files in src/coeff, then Project > Clean and Build.
 * .incbin embeds bytes into the ELF. No run-time host filesystem is needed.
 * Clean after changing MEM files: C dependency lists do not track .incbin.
 */
#include "ce_coeff.h"
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#define EMBED_FILE(symbol, path) \
    __asm__(".pushsection .rodata.ce_coeff_files,\"a\",%progbits\n" \
            ".balign 4\n.global " #symbol "_begin\n" \
            #symbol "_begin:\n.incbin \"" path "\"\n" \
            ".global " #symbol "_end\n" \
            #symbol "_end:\n.popsection\n"); \
    extern const unsigned char symbol##_begin[], symbol##_end[]

/* PC paths resolved at build time, relative to Debug/Release. */
EMBED_FILE(coeff_re1, "../src/coeff/h_re.mem");
EMBED_FILE(coeff_im1, "../src/coeff/h_im.mem");



static CeCoeffImage image;
/* Vitis Expressions: finished=1 means result is valid. */
volatile int ce_coeff_result = CE_BAD_FORMAT;
volatile unsigned ce_coeff_finished = 0;
static int whitespace(unsigned char c)
{
    return c==' ' || c=='\t' || c=='\r' || c=='\n';
}
int ce_coeff_parse_mem(const unsigned char *data, size_t size, uint32_t *values)
{
    size_t pos=0;
    unsigned point;
    if(!data || !values) return CE_BAD_FORMAT;
    if(size>=3 && data[0]==0xef && data[1]==0xbb && data[2]==0xbf) pos=3;
    for(point=0;point<CE_COEFF_POINTS;point++) {
        char token[6];
        unsigned digit;
        while(pos<size && whitespace(data[pos])) pos++;
        if(size-pos<5) return CE_BAD_FORMAT;
        for(digit=0;digit<5;digit++) token[digit]=(char)data[pos++];
        token[5]='\0';
        if(ce_coeff_parse_hex(token,&values[point])!=CE_OK) return CE_BAD_FORMAT;
        if(pos<size && !whitespace(data[pos])) return CE_BAD_FORMAT;
    }
    while(pos<size && whitespace(data[pos])) pos++;
    return pos==size ? CE_OK : CE_BAD_FORMAT;
}
void ce_coeff_run(void)
{
    const unsigned char *const begin[2]={
        coeff_re1_begin,coeff_im1_begin
    };
    const unsigned char *const end[2]={
        coeff_re1_end,coeff_im1_end
    };
    const char *const names[2]={"h_re.mem","h_im.mem"};
    unsigned file;
    int rc;
    ce_coeff_finished=0;
    printf(">> Coefficients: validating two embedded MEM files\r\n");
    for(file=0;file<2;file++) {
        size_t size=(size_t)((uintptr_t)end[file]-(uintptr_t)begin[file]);
        rc=ce_coeff_parse_mem(begin[file],size,image.file[file]);
        if(rc!=CE_OK) {
            ce_coeff_result=rc;
            ce_coeff_finished=1;
            printf(">> COEFF ERROR: %s needs 300 five-digit hex values (00000..3FFFF)\r\n",names[file]);
            return;
        }
        printf(">> %s: 300 points OK\r\n",names[file]);
    }
    printf(">> Loading first FIR path through AXI...\r\n");
    rc=ce_coeff_load(&image,1000u);
    ce_coeff_result=rc;
    ce_coeff_finished=1;
    if(rc==CE_OK)
        printf(">> COEFF DONE: enabled signal paths started with new coefficients\r\n");
    else
        printf(">> COEFF ERROR: code=%d HW=0x%08lx\r\n",rc,(unsigned long)ce_coeff_last_hw_error());
}