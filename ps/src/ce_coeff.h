#ifndef CE_COEFF_H
#define CE_COEFF_H
#include <stdint.h>
#include <stddef.h>
#define CE_COEFF_POINTS 300u
/* File order: first-path real, first-path imaginary.
 * Values are RAW 18-bit two's complement, zero-extended to uint32_t. */
typedef struct { uint32_t file[2][CE_COEFF_POINTS]; } CeCoeffImage;
enum { CE_OK=0, CE_BAD_FORMAT=-1, CE_TIMEOUT=-2, CE_HW_ERROR=-3, CE_BAD_ID=-4 };
uint32_t ce_coeff_crc_word(uint32_t crc, uint32_t word);
int ce_coeff_parse_hex(const char *line, uint32_t *value);
int ce_coeff_load(const CeCoeffImage *image, uint32_t timeout_ms);
uint32_t ce_coeff_last_hw_error(void);
int ce_coeff_parse_mem(const unsigned char *data, size_t size, uint32_t *values);
void ce_coeff_run(void);
extern volatile int ce_coeff_result;
extern volatile unsigned ce_coeff_finished;
#endif
