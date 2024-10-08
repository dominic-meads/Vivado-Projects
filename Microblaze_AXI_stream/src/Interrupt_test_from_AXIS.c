#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"

XIntc InterruptController;
int Status;
int data[30];

// ISR
void MyISR(void *CallbackRef)
{
    for (int i = 0; i <= 29; i++)
    {
	    getfsl(data[i], 0);
    }
}

int main()
{
    init_platform();

    // Initialize the interrupt controller driver
    Status = XIntc_Initialize(&InterruptController, XPAR_INTC_0_DEVICE_ID);

    // Connect the interrupt handler to the ISR
    Status = XIntc_Connect(&InterruptController, 0,
                           (XInterruptHandler)MyISR, 0);

    // Start the interrupt controller
    Status = XIntc_Start(&InterruptController, XIN_REAL_MODE);

    // Enable interrupts in the MicroBlaze processor
    XIntc_Enable(&InterruptController, 0);
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XIntc_InterruptHandler,
                                 &InterruptController);

    Xil_ExceptionEnable();

    while(1)
    {
        for (int i = 0; i <= 29; i++)
        {
      	  xil_printf("%d\n\r",data[i]);
        }
    }

    cleanup_platform();
}
