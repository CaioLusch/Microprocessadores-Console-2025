/*
Esse programa PRECISA SER O PRIMEIRO na lista de arquivos do projeto 

.org 0x20
RTI:
stackframe

call animacao 

eret
*/

/*
    CPU opera em 50 MHz
    fazer calculo para quanto vale 200 ms
    configurar o timer para quando chegar nesse valor de contagem, gerar interrupções
    Na 5ª interrupção, 1s terá passado, aí trato tanto da animação quanto do cronometro
*/

.org    0x20
/* Exception handler */

    
    rdctl   et, ipending                        /* Check if external interrupt occurred */
    beq     et, r0, OTHER_EXCEPTIONS            /* If zero, check exceptions */
    subi    ea, ea, 4                           /* Hardware interrupt, decrement ea to execute the interrupted instruction upon return to main program */

    andi    r13, et, 1
    beq     r13, r0, OTHER_INTERRUPTS           /* Check if irq0 asserted */
    call    EXT_IRQ0                            /* If yes, go to IRQ0 service routine, 0 = timer, ou seja interrupção gerada pelo timer */


OTHER_INTERRUPTS:
/* Instructions that check for other hardware interrupts should be placed here */

        br      END_HANDLER


OTHER_EXCEPTIONS:
/* Instructions that check for other types of exceptions should be placed here */


END_HANDLER:
    eret                               /* Return from exception */

.org    0x100
/* Interrupt-service routine for the desired hardware interrupt */
EXT_IRQ0:
    # verificar as flags de animacao e do cronometro, executar as acoes que estiverem setadas como TRUE
    # pensando que as flags estao em um registrador, precisaremos trata-los como global 

    bne r_, r18, END_IRQ0

    ANIM:
        call CALL_ANIMATION

    END_IRQ0:


        ret                               /* Return from the interrupt-service routine */