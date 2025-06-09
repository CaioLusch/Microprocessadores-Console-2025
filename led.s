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
    r7: endereço de BUFFER_COMMAND                                                  (inicializado na main)
    r8: ininicalmente, contem a string padrao pedindo para inserir um comando       (não usado nesse arquivo)
    r9: endereço de enter                                                           (também não usado nesse arquivo)
    r10: valores de comparacao para os condicionais para verificar qual a instrução a ser executada
    r11: valor contido no endereço atual de BUFFER_COMMAND
    r12: endereco dos leds vermelhos
    r13: estado atual dos LEDs
    r14: número do LED

*/
.global CALL_LED
CALL_LED:
    
    /* PRÓLOGO */
    subi sp, sp, 8                     /* reserve space on the stack */
    stw r13, 0(sp)
    stw r4, 4(sp)                      /* save register */
    
    movia r12, 0x10000000              /* endereço do led vermelho */
    ldwio r13, (r12)                   /* leitura do endereço dos leds vermelhos (estado atual dos leds) */

    ldb r11, 1(r7)                     /* atualizar para o proximo codigo do vetor  */
    subi r11, r11, 0x30                /* converte ASCII para número */

    /* Verifica se comando[1] == 0 → apagar */
    
    addi r10, r0, 0                    /* zerar a variavel de comparacao */
    beq r11, r10, ACENDER              /* Verificar se condiz com comando de acender */
    
    /* Verifica se comando[1] == 1 → apagar */
    addi r10, r10, 1
    beq r11, r10, APAGAR               /* Verificar se condiz com o comando de apagar */

    br END_LED                         /* Se chegou aqui, é porque o comando era inválido */

    ACENDER:
        
        /* lê comando[2] e comando[3] (ASCII) e converte para número */
        ldb r4, 2(r7)
        subi r4, r4, 0x30             /* leitura do penúltimo digito (__x_) */

        ldb r5, 3(r7)
        subi r5, r5, 0x30             /* leitura do último dígito (___x) */

        muli r4, r4, 10               /* Multiplicar dezena por 10, porque né, DEZENA */ 
        add r14, r4, r5               /* r14 = número do LED */

        /* criação da máscara: 1 << r14 */
        movi r4, 1
        sll r4, r4, r14

        or r13, r13, r4              /* acender bit correspondente */
        stwio r13, 0(r12)            /* escreve novo valor no endeço do LED */
        br END_LED

    APAGAR:
        /* leitura comando[2] e cpmando[3] em ascii e converter para número */
        ldb r4, 2(r7)
        subi r4, r4, 0x30           /* penúltimo dígito da instrução */

        ldb r5, 3(r7)
        subi r5, r5, 0x30           /* último digito da instrução */

        muli r4, r4, 10
        add r14, r4, r5              /* r14 = número do LED */

        movi r4, 1
        sll r4, r4, r14              /* cria máscara */

        not r4, r4                   /* inverte bits para apagar */
        and r13, r13, r4             /* apaga bit correspondente */
        stwio r13, 0(r12)
        br END_LED

    END_LED:
        /* EPÍLOGO */   
        ldw r13, 0(sp)          
        ldw r4, 4(sp)                      /* pop the stack frame */
        addi sp, sp, 4                     /* update stack poiter */
        
        ret                                /* return to the calee */

