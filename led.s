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
    r4: flag animacao
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
    r15: temp para calculo da dezena

*/
.global CALL_LED
CALL_LED:
    
    /* PRÓLOGO */
    subi sp, sp, 24      # Mais espaço para salvar registradores
    stw r4, 0(sp)
    stw r5, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r13, 16(sp)
    stw r14, 20(sp)
    
    movia r13, LEDS_MANUAIS_STATE
    ldw r13, 0(r13)                    /* r13 agora contém o estado manual salvo */

    ldb r11, 1(r7)                     /* atualizar para o proximo codigo do vetor  */

    /* Verifica se comando[1] == 0 → apagar */
    addi r10, r0, 0                    /* zerar a variavel de comparacao */
    beq r11, r10, ACENDER              /* Verificar se condiz com comando de acender */
    
    /* Verifica se comando[1] == 1 → apagar */
    addi r10, r10, 1
    beq r11, r10, APAGAR               /* Verificar se condiz com o comando de apagar */

    br END_LED                         /* Se chegou aqui, é porque o comando era inválido */

    ACENDER:
        
        /* lê comando[2] e comando[3] (ASCII) e converte para número */
        ldb r4, 2(r7)                        /* leitura do penultimo digito (__x_) */
        ldb r5, 3(r7)                        /* leitura do ultimo dígito (___x)    */             

        /* Multiplicar dezena por 10, porque né, DEZENA */ 
        slli r4, r4, 1                      /* multiplica por 2 */ 
        slli r15, r4, 2                     /* multiplica por 8 */
        add r4, r4, r15                     /* 8x + 2x = 10x    */

        add r14, r4, r5                     /* r14 = número do LED                          */


        /* criação da máscara: 1 << r14 */
        movi r4, 1
        sll r4, r4, r14

        or r13, r13, r4              /* acender bit correspondente */
        
        br SAVE_AND_UPDATE

    APAGAR:
        
        /* lê comando[2] e comando[3] (ASCII) e converte para número */
        ldb r4, 2(r7)                        /* leitura do penultimo digito (__x_) */
        ldb r5, 3(r7)                        /* leitura do ultimo dígito (___x)    */             

        /* Multiplicar dezena por 10, porque né, DEZENA */ 
        slli r4, r4, 1                      /* multiplica por 2 */ 
        slli r15, r4, 2                     /* multiplica por 8 */
        add r4, r4, r15                     /* 8x + 2x = 10x    */

        add r14, r4, r5                     /* r14 = número do LED                          */


        /* criação da máscara: 1 << r14 */
        movi r4, 1
        sll r4, r4, r14

        nor r4, r4, r4               /* inverte bits para apagar */
        and r13, r13, r4             /* apaga bit correspondente */
        br SAVE_AND_UPDATE

    SAVE_AND_UPDATE:
        movia r4, LEDS_MANUAIS_STATE
        stw r13, 0(r4)
        
        /* Verifica se a animação está rodando. */
        movia r4, FLAG_ANIMACAO
        ldw r5, 0(r4)
        movi r10, 1
        beq r5, r10, END_LED         /* Se animação está LIGADA, pula a escrita no hardware e retorna */

        /* Se a animação está DESLIGADA, atualiza o hardware agora */
        
        movia r4, 0x10000000 # Endereço do hardware dos LEDs
        stwio r13, 0(r4)     # Escreve o novo estado manual nos LEDs físicos

    END_LED:
        /* EPÍLOGO */   
        ldw r4, 0(sp)
        ldw r5, 4(sp)
        ldw r10, 8(sp)
        ldw r14, 12(sp)
        ldw r15, 16(sp)
        addi sp, sp, 20
        
        ret                                /* return to the calee */
