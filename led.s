/*

    IDEIA DE FUNCIONAMENTO DO CÓDIGO:

    switch(comando[1]):
        
        case 0: ACENDER
            verificar comando[2] e comando[3]
            assim que tiver esses 2 valores, consigo saber qual Led deve ser aceso
            ir até o endereço, e reescrever o valor
        
        case 1: APAGAR
            endere comando[2] e comando[4]
        
*/

/*
    r5: usado em subrotinas
    r6: UART port 
    r7: endereço de BUFFER_COMMAND
    r8: ininicalmente, contem a string padrao pedindo para inserir um comando
    r9: endereço de enter
    r10: valores de comparacao para os condicionais para verificar qual a instrução a ser executada
    r11: valor contido no endereço atual de BUFFER_COMMAND
    r12: endereco dos leds vermelhos

*/
.global CALL_LED
CALL_LED:
    
    /* PRÓLOGO */
    subi sp, sp, 8                     /* reserve space on the stack */
    stw r13, 0(sp)
    stw r4, 4(sp)                      /* save register */
    
    movia r12, 0x10000000              /* endereço do led vermelho */
    ldwio r13, (r12)                   /* leitura do endereço dos leds vermelhos */

    ldb r11, 1(r7)                     /* atualizar para o proximo codigo do vetor  */
    addi r10, r0, 0                    /* zerar a variavel de comparacao */
    beq r11, r10, ACENDER              /* Verificar se condiz com comando de acender */
    
    addi r10, r10, 1
    beq r11, r10, APAGAR               /* Verificar se condiz com o comando de apagar */

    br END_LED                         /* Se chegou aqui, é porque o comando era inválido */

    ACENDER:
        br END_LED

    APAGAR:
        br END_LED

    END_LED:
        /* EPÍLOGO */   
        ldw r13, 0(sp)          
        ldw r4, 4(sp)                      /* pop the stack frame */
        addi sp, sp, 4                     /* update stack poiter */
        
        ret                                /* return to the calee */

