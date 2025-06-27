/*
    CPU opera em 50 MHz
    fazer calculo para quanto vale 200 ms
    configurar o timer para quando chegar nesse valor de contagem, gerar interrupções
    Na 5ª interrupção, 1s terá passado, aí trato tanto da animação quanto do cronometro
*/

.equ TIMER_BASE, 0x10002000
.org    0x20
.global RTI
RTI:
    /* PRÓLOGO */
        subi sp, sp, 8                     /* reserve space on the stack */
        stw r13, 0(sp)
        stw r4, 4(sp)                      /* save register */

    /* Exception handler */

        
        rdctl   et, ipending                        /* Check if external interrupt occurred */
        beq     et, r0, OTHER_EXCEPTIONS            /* If zero, check exceptions */
        subi    ea, ea, 4                           /* Hardware interrupt, decrement ea to execute the interrupted instruction upon return to main program */

        andi    r13, et, 4
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

        /* PROLOGO */
        subi sp, sp, 12
        stw r4, 0(sp)
        stw r5, 4(sp)
        stw ra, 8(sp)

        movi r5, TIMER_BASE
        stwio r0, 0(r5)                             /* LIMPA a flag de interrupção do timer (escreve no registrador de status, offset 0) */

        movi r4, 1
        bne r18, r4, END_IRQ0                       /* Verifica se a flag de animação (r18) está ativa */
    
        call CALL_ANIMATION                         /* Se a flag estiver ativa, chama animacao */

    END_IRQ0:
        /* EPILOGO */
        ldw r4, 0(sp)
        ldw r5, 4(sp)
        ldw ra, 8(sp)
        addi sp, sp, 12
    
/* EPÍLOGO */   
    ldw r13, 0(sp)          
    ldw r4, 4(sp)                      /* pop the stack frame */
    addi sp, sp, 4                     /* update stack poiter */

eret  /* Return from the interrupt-service routine */