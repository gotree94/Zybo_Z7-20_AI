
#include "xil_io.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"

/*
 * Vitis app for Week02 AXI-Lite ALU test
 * Assumes a packaged IP with VLNV user.org:user:my_axi_alu:1.0
 * mapped at base address XPAR_MY_AXI_ALU_0_S00_AXI_BASEADDR (auto-generated).
 */

#ifndef XPAR_MY_AXI_ALU_0_S00_AXI_BASEADDR
#warning "XPAR_MY_AXI_ALU_0_S00_AXI_BASEADDR is not defined. Check xparameters.h and your IP instance name."
#define ALU_BASE 0x43C00000U
#else
#define ALU_BASE XPAR_MY_AXI_ALU_0_S00_AXI_BASEADDR
#endif

static inline void alu_write(unsigned offset, unsigned val) { Xil_Out32(ALU_BASE + offset, val); }
static inline unsigned alu_read(unsigned offset) { return Xil_In32(ALU_BASE + offset); }

int main()
{
    xil_printf("Zybo Z7-20 AXI ALU test start\r\n");

    // Test vectors
    unsigned a = 5, b = 3;
    for (unsigned opcode = 0; opcode <= 4; ++opcode) {
        alu_write(0x0, a);       // REG0 = a (8-bit used)
        alu_write(0x4, b);       // REG1 = b (8-bit used)
        alu_write(0x8, opcode);  // REG2 = opcode (3-bit used)

        unsigned result = alu_read(0xC); // REG3 = result (lower 16-bit valid)
        xil_printf("a=%u, b=%u, opcode=%u => result=%u (0x%08X)\r\n",
                   a, b, opcode, result, result);
        sleep(1);
    }

    xil_printf("Test done.\r\n");
    return 0;
}
