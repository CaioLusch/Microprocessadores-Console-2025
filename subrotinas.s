.global PUT_JTAG

PUT_JTAG:

    /* save any modified registers */
    subi sp, sp, 4                  /* reserve space on the stack */
    stw r4, 0(sp)                   /* save register */

    ldwio r4, 4(r6)                 /* read the JTAG UART Control register */
    andhi r4, r4, 0xffff            /* check for write space */
    beq r4, r0, END_PUT             /* if no space, ignore the character */
    stwio r5, 0(r6)                 /* send the character */

    END_PUT:
    /* restore registers */             
    ldw r4, 0(sp)                       /* pop the stack frame */
    addi sp, sp, 4                      /* update stack poiter */
    ret                                 /* return to the calee */


.global GET_JTAG                    /* scanf para ler qual instrução será executada */

GET_JTAG:            
                   
    subi sp, sp, 8                  /* reserve space on the stack */
    stw ra, 0(sp)                   /* save register */
    stw r4, 4(sp)                   /* save register */
    movia r7, BUFFER_COMMAND        /* r7 recebe o endereço do buffer */

GET_POLL:
    ldwio r4, 0(r6)                 /* read the JTAG UART Data register */
    andi r8, r4, 0x8000             /* check if there is new data */
    beq r8, r0, GET_POLL            /* if no data, wait */

    andi r5, r4, 0x00ff             /* the data is in the least significant byte */
    movi r9, 0x0A                  /* endereço de ENTER (ou LF) */
    
    beq r5, r9, END_GET             /* verifica se char é ENTER */
    call PUT_JTAG                   /* echo character */
    
    /*  acessar endereço do BUFFER_COMMAND, e escrever lá o ultimo bit digitado no terminal  */
    subi r5, r5, 0x30               /* sub 30 para transformar de ascii para numero */
    stb r5, (r7)                    /* r5 tem o ultimo digito inserido pelo usuario, preciso escreve-lo no buffer BUFFER_COMMAND */
    addi r7, r7, 1                  /* atualização do indice do vetor do buffer */


    br GET_POLL

    END_GET:
    /* restore registers */             
    ldw ra, 0(sp)                   /* save register */
    ldw r4, 4(sp)                       /* pop the stack frame */
    addi sp, sp, 8                      /* update stack poiter */
    
    ret


.global SUB_LED
SUB_LED:
ret

.global SUB_CRONOMETRO
SUB_CRONOMETRO:
ret

.global SUB_ANIMACAO
SUB_ANIMACAO:
ret
/*

*/