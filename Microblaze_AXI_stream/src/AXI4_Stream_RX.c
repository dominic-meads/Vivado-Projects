/******************************************************************************/
/**
*
* File: UARTLite_test.c
*
* Description: example of minimal Tx testing of the UART Lite core v2.0, and sends
*              the entire english alphabet at 9600 Buad, 8 data bits, no parity,
*
* Notes:
*
*
* MODIFICATION HISTORY:
* <pre>
* Ver   Who  Date	 Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a DM   8/12/21  First release
* </pre>
******************************************************************************/

/***************************** Include Files *********************************/

#include "platform.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "xparameters.h"
#include "xuartlite.h"
#include "mb_interface.h"

/************************** Constant Definitions *****************************/

#define UARTLITE_DEVICE_ID  XPAR_UARTLITE_0_DEVICE_ID

// 26 letters in alphabet
#define TX_DATA_SIZE  26

// max size in non-interrput mode
#define TX_BUFF_SIZE  16

#define AXI4_STREAM_ID 0

#define getfsl(val, id)         asm volatile ("get\t%0,rfsl" stringify(id) : "=d" (val))

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

int UARTLite_Init_SelfTest(u16 DeviceID);

int SendData(u8 *TxDataPointer, u8 *TxDataBufferPointer);

/************************** Variable Definitions *****************************/

// Data to send
u8 TxData[TX_DATA_SIZE];

// Tx buffers
u8 TxBuff[TX_BUFF_SIZE];

// instance of UART Lite core
XUartLite UartLite0;


/*****************************************************************************/
/**
*
* Description: main function to test out the UART Lite
*
*
* Arguments:
*
*
* Returns: XST_SUCCESS if successful, otherwise XST_FAILURE.
*
*
* Notes:
*
******************************************************************************/
int main()
{
  int UartLiteStatus;
  int TxStatus;

  init_platform();

  UartLiteStatus = UARTLite_Init_SelfTest(UARTLITE_DEVICE_ID);

  // disable interrupts
  microblaze_disable_interrupts();

//  // pg. 54 of UG984 -- Avoiding Data Hazards suggests to fetch a data packet like this:
//  static int data;           // can be an array
//  register int d0;           // can be up to 16 general purpose registers
//  getfsl(d0,AXI4_STREAM_ID); // "get" instructions executed using different registers
//  data = d0;                 // data is stored after
//  xil_printf("Data from AXI4-Stream: %d\n\r\n\r",data);

  int data[20];

  for (int i = 0; i <= 19; i++)
  {
	  getfsl(data[i], 0);  // 200 Samples per second
  }

  for (int i = 0; i <= 19; i++)
  {
	  xil_printf("Data from AXI4-Stream (Sample %d): %d\n\r\n\r",i,data[i]);
  }

  cleanup_platform();
  return XST_SUCCESS;
}


/*****************************************************************************/
/**
*
* Description: Initializes UART Lite and does a self test
*
*
* Arguments: DeviceID is the DeviceId is the Device ID of the UartLite and is the
*		         XPAR_<uartlite_instance>_DEVICE_ID value from xparameters.h.
*
*
* Returns: XST_SUCCESS if successful, otherwise XST_FAILURE.
*
*
* Notes:
*
******************************************************************************/
int UARTLite_Init_SelfTest(u16 DeviceID)
{
  int Status;

  // perform initialization tests
  Status = XUartLite_Initialize(&UartLite0, DeviceID);
  if (Status != XST_SUCCESS)
  {
    return XST_FAILURE;
  }

  // perform self-test tests
  Status = XUartLite_SelfTest(&UartLite0);
  if (Status != XST_SUCCESS)
  {
    return XST_FAILURE;
  }

  return XST_SUCCESS;
}
