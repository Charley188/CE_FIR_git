/*
 * main.c
 *
 *  Created on: 2023Äê11ÔÂ8ÈÕ
 *      Author: Administrator
 */
#include "parameters.h"
#include <stdio.h>

#include "delay.h"
#include "xgpiops.h"


XGpioPs _xgpio_ps;

static void GpioPs_SetOutputEnablePin(const XGpioPs *InstancePtr, u32 Pin, u32 OpEnable)
{
	u8 Bank;
	u8 PinNumber;
	u32 OpEnableReg;

//	Xil_AssertVoid(InstancePtr != NULL);
//	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
//	Xil_AssertVoid(Pin < InstancePtr->MaxPinNum);
//	Xil_AssertVoid(OpEnable <= (u32)1);

	/* Get the Bank number and Pin number within the bank. */
#ifdef versal
	XGpioPs_GetBankPin(InstancePtr,(u8)Pin, &Bank, &PinNumber);
#else
	XGpioPs_GetBankPin((u8)Pin, &Bank, &PinNumber);
#endif

	OpEnableReg = XGpioPs_ReadReg(InstancePtr->GpioConfig.BaseAddr,
				       ((u32)(Bank) * XGPIOPS_REG_MASK_OFFSET) +
				       XGPIOPS_OUTEN_OFFSET);

	if (OpEnable != (u32)0) { /*  Enable Output Enable */
		OpEnableReg |= ((u32)1 << (u32)PinNumber);
	} else { /* Disable Output Enable */
		OpEnableReg &= ~ ((u32)1 << (u32)PinNumber);
	}

	XGpioPs_WriteReg(InstancePtr->GpioConfig.BaseAddr,
			  ((u32)(Bank) * XGPIOPS_REG_MASK_OFFSET) +
			  XGPIOPS_OUTEN_OFFSET, OpEnableReg);
}

static void GpioPs_SetDirectionPin(const XGpioPs *InstancePtr, u32 Pin, u32 Direction)
{
	u8 Bank;
	u8 PinNumber;
	u32 DirModeReg;

//	Xil_AssertVoid(InstancePtr != NULL);
//	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
//	Xil_AssertVoid(Pin < InstancePtr->MaxPinNum);
//	Xil_AssertVoid(Direction <= (u32)1);

	/* Get the Bank number and Pin number within the bank. */
#ifdef versal
	XGpioPs_GetBankPin(InstancePtr,(u8)Pin, &Bank, &PinNumber);
#else
	XGpioPs_GetBankPin((u8)Pin, &Bank, &PinNumber);
#endif
	DirModeReg = XGpioPs_ReadReg(InstancePtr->GpioConfig.BaseAddr,
				      ((u32)(Bank) * XGPIOPS_REG_MASK_OFFSET) +
				      XGPIOPS_DIRM_OFFSET);

	if (Direction!=(u32)0) { /*  Output Direction */
		DirModeReg |= ((u32)1 << (u32)PinNumber);
	} else { /* Input Direction */
		DirModeReg &= ~ ((u32)1 << (u32)PinNumber);
	}

	XGpioPs_WriteReg(InstancePtr->GpioConfig.BaseAddr,
			 ((u32)(Bank) * XGPIOPS_REG_MASK_OFFSET) +
			 XGPIOPS_DIRM_OFFSET, DirModeReg);
}

static void GpioPs_WritePin(const XGpioPs *InstancePtr, u32 Pin, u32 Data)
{
	u32 RegOffset;
	u32 Value;
	u8 Bank;
	u8 PinNumber;
	u32 DataVar = Data;

//	Xil_AssertVoid(InstancePtr != NULL);
//	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);
//	Xil_AssertVoid(Pin < InstancePtr->MaxPinNum);

	/* Get the Bank number and Pin number within the bank. */
#ifdef versal
	XGpioPs_GetBankPin(InstancePtr,(u8)Pin, &Bank, &PinNumber);
#else
	XGpioPs_GetBankPin((u8)Pin, &Bank, &PinNumber);
#endif

	if (PinNumber > 15U) {
		/* There are only 16 data bits in bit maskable register. */
		PinNumber -= (u8)16;
		RegOffset = XGPIOPS_DATA_MSW_OFFSET;
	} else {
		RegOffset = XGPIOPS_DATA_LSW_OFFSET;
	}

	/*
	 * Get the 32 bit value to be written to the Mask/Data register where
	 * the upper 16 bits is the mask and lower 16 bits is the data.
	 */
	DataVar &= (u32)0x01;
	Value = ~((u32)1 << (PinNumber + 16U)) & ((DataVar << PinNumber) | 0xFFFF0000U);
	XGpioPs_WriteReg(InstancePtr->GpioConfig.BaseAddr,
			  ((u32)(Bank) * XGPIOPS_DATA_MASK_OFFSET) +
			  RegOffset, Value);

}


/****************************************************************************/
/**
*
* Main function that invokes the polled example in this file.
*
* @param	None.
*
* @return
*		- XRFDC_SUCCESS if the example has completed successfully.
*		- XRFDC_FAILURE if the example has failed.
*
* @note		None.
*
*****************************************************************************/

int main(void)
{
	int Status;
	u32 Value;

	u16 Tile;
	u16 Block;


	 _xgpio_ps.GpioConfig.BaseAddr = XPAR_PSU_GPIO_0_BASEADDR;
	 _xgpio_ps.GpioConfig.DeviceId = XPAR_PSU_GPIO_0_DEVICE_ID;
	 GpioPs_SetDirectionPin(&_xgpio_ps, 78+2, 1);
	 GpioPs_SetOutputEnablePin(&_xgpio_ps, 78+2, 1);
	 GpioPs_SetDirectionPin(&_xgpio_ps, 78+95, 1);
	 GpioPs_SetOutputEnablePin(&_xgpio_ps, 78+95, 1);
//	 	Xil_Out32(XPAR_PARAM_BASEADDR + 2*4, 0);
//	 	Xil_Out32(XPAR_PARAM_BASEADDR + 0*4, 0);

	GpioPs_WritePin(&_xgpio_ps, 78+95, 1);
	usleep(500);

	GpioPs_WritePin(&_xgpio_ps, 78+95, 0);
	usleep(500);

	GpioPs_WritePin(&_xgpio_ps, 78+95, 1);
	usleep(500);
	GpioPs_WritePin(&_xgpio_ps, 78+2, 0);
	usleep(500);

#if 1
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + ADC0_RESTART_STATE_REG, 0x00000001);	//adc
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + ADC0_POWER_STATE_REG, 0x00000001);
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + DAC0_RESTART_STATE_REG, 0x00000001);	//dac
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + DAC0_POWER_STATE_REG, 0x00000001);
	 usleep(100);

	 sleep(1);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + DAC0_RESTART_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0000C008 <%lx>\r\n", Value); // START_END_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + DAC0_CURRENT_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0000C00C <%lx>\r\n", Value); // CURRENT_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + ADC0_RESTART_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x00014008 <%lx>\r\n", Value); // START_END_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + ADC0_CURRENT_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0001400C <%lx>\r\n", Value); // CURRENT_STATE_ADDR
	 usleep(100);

	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + ADC0_RESTART_STATE_REG, 0x00000106);	//adc
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + ADC0_POWER_STATE_REG, 0x00000001);
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + DAC0_RESTART_STATE_REG, 0x00000108);	//dac
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + DAC0_POWER_STATE_REG, 0x00000001);
	 usleep(100);

	 sleep(1);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + DAC0_RESTART_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0000C008 <%lx>\r\n", Value); // START_END_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + DAC0_CURRENT_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0000C00C <%lx>\r\n", Value); // CURRENT_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + ADC0_RESTART_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x00014008 <%lx>\r\n", Value); // START_END_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + ADC0_CURRENT_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0001400C <%lx>\r\n", Value); // CURRENT_STATE_ADDR
	 usleep(100);

	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + DAC0_RESTART_STATE_REG, 0x0000080F);	//dac
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + DAC0_POWER_STATE_REG, 0x00000001);
	 usleep(100);

	 sleep(1);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + DAC0_RESTART_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0000C008 <%lx>\r\n", Value); // START_END_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + DAC0_CURRENT_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0000C00C <%lx>\r\n", Value); // CURRENT_STATE_ADDR
	 usleep(100);

	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + ADC0_RESTART_STATE_REG, 0x0000060F);	//adc
	 usleep(100);
	 Xil_Out32(USP_RF_DATA_CONV_BASEADDR + ADC0_POWER_STATE_REG, 0x00000001);
	 usleep(100);

	 sleep(1);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + ADC0_RESTART_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x00014008 <%lx>\r\n", Value); // START_END_STATE_ADDR
	 usleep(100);
	 Value = Xil_In32(USP_RF_DATA_CONV_BASEADDR + ADC0_CURRENT_STATE_REG);
	 xil_printf(">> RF_DATA_CONV_IP_Ver reg0x0001400C <%lx>\r\n", Value); // CURRENT_STATE_ADDR
	 usleep(100);
#endif

	printf(">> Done.\r\n");

	while(1);

	return 0;
}
