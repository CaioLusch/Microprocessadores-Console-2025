/*
    r5: usado em subrotinas
    r6: UART port 
    r7: endereço de BUFFER_COMMAND                                                                      (inicializado na main)
    r8: ininicalmente, contem a string padrao pedindo para inserir um comando                           (não usado nesse arquivo)
    r9: endereço de enter                                                                               (também não usado nesse arquivo)
    r10: valores de comparacao para os condicionais para verificar qual a instrução a ser executada
    r11: valor contido no endereço atual de BUFFER_COMMAND
    r12: endereco dos leds vermelhos (referencial para todas as outras)
    r13: estado atual dos LEDs
    r14: número do LED
    r15: temp para calculo da dezena
    r16: estado aceso
    r17: timer
    r18: Flag para animacao e cronometro

*/

.equ COUNTER, 0x2000
.global PUT_JTAG

PUT_JTAG:

    /* save any modified registers */
    subi sp, sp, 4                  /* reserve space on the stack */
    stw r4, 0(sp)                   /* save register */

PUT_JTAG_POLL:
    ldwio r4, 4(r6)                 /* read the JTAG UART Control register */
    andhi r4, r4, 0xffff            /* check for write space */
    beq r4, r0, PUT_JTAG_POLL             /* if no space, ignore the character */
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

/* 
Timer gera interrupções a cada 200 ms, apenas isso
tratamento de interrupções verifica de quem veio a interrupção
após isso, checa as flags de animacao e do cronometro
realiza as acoes necessarias conforme as flags

esse código do timer será eecutado apenas uma vez, para setupar o que o timer deve fazer
uma vez executado, o timer (hardware) estará configurado para gerar interrupções a acada 200 ms, portanto sem problemas com o código
o que é necessário é, dentro desses tratamentos de interrupção, verificar se as flags estão ativas ou n e executar as que estiverem 

tá tá tá, mas o que isso implica?
    simples, se a interrupção é gerada a cada 200ms, precisamos que entre uma e outra o led fique aceso, dando exatamente o tempo de 200 ms
*/

.global SET_TIMER
SET_TIMER:

    /* PRÓLOGO */
    subi sp, sp, 12                      /* reserve space on the stack */
    stw r13, 0(sp)
    stw r4, 4(sp)                       /* save register */
    stw r5, 8(sp)


    ldwio r17, COUNTER(r12)     /* Pegar leitura do timer */
    
    movia r4, 10000000          /* valor de contagem necessário para passar 200 ms */

    andi r5, r4, 0xffff         /* r5 contém a parte baixa */
    stwio r5, 2008(r12)           /*store da parte low */

    srli r4, r4, 16             /* r4 contem parte alta */
    stwio r4, 200C(r12)         /* escreve a parte alta na memoria */

    movi r4, 0b0111             /* STOP = 0, START = 1, CONT = 1, ITO = 1 */
    ldwio r4, 2004(r12)         

    /* EPILOGO */ 
    ldw r5, 8(sp)
    ldw r4, 4(sp)
    ldw r13, 0(sp)
    addi sp, sp, 12

ret