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

*/

/*
    lógica do programa:
    if(lever == 1)
        LOOP_DIR_ESQ:
            setar todos os leds como 0 (util para caso venha depois de acender individualmente um led)
            i = 0
            acender(led[i])
            apagar(led[i])
            i++

            if i > 17 STOP
            br LOOP
    else{
        LOOP_ESQ_DIR:
            setar todos como 0
            i = 17 
            acender(led[i])
            apagar(led[i])
            
            if i = 0, STOP
            i--
        br loop
    }

a rotina precisa continuar rodando, mas o usuário precisa ser capaz de digitar novos comandos mesmo durante a execução, como?
    interrupção
    Não é possível fazer o programa executar dois locais ao mesmo tempo, por isso precisamos da interrupção

consideração importante: não há passagem de tempo entre uma chamada do contador e outra (processador é muito mais rápido)

*/
.equ SWITCH, 0x40

.global CALL_ANIMATION
CALL_ANIMATION:
    
    /* PRÓLOGO */
    subi sp, sp, 12                      /* reserve space on the stack */
    stw r13, 0(sp)
    stw r4, 4(sp)                       /* save register */
    stw r5, 8(sp)

    movia r12, 0x10000000               /* endereço do led vermelho */
    ldwio r13, (r12)                    /* leitura do endereço dos leds vermelhos (estado atual dos leds) */

    movi r10, 17
    stwio r0, 0(r12)                    /* garantir que todos os LEDS estao apagados */

    ldwio r5, SWITCH(r12)               /* r5 le no endereco da alavanca */
    movi r4, 1
    and r5, r5, r4
    
    beq r5, r4, LOOP_ESQ_DIR

    LOOP_DIR_ESQ:
        mov r8, zero                       /* numero do led a ser aceso */

        ANIM_ACENDER_DE:
        
            /* criação da máscara: 1 << r8 */
            movi r4, 1
            sll r4, r4, r8

            or r16, r13, r4              /* acender bit correspondente */
            stwio r16, 0(r12)            /* escreve novo valor no endeço do LED */
    
        ANIM_APAGAR_DE:
            stwio zero, 0(r12)
        
        addi r8, r8, 1

        bgt r8, r10, END_ANIMATION
        br ANIM_ACENDER_DE

    LOOP_ESQ_DIR:
        movia r8, 17

        ANIM_ACENDER_ED:
            movi r4, 1
            sll r4, r4, r8

            or r16, r13, r4              /* acender bit correspondente */
            stwio r16, 0(r12)            /* escreve novo valor no endeço do LED */

        WAIT_MS:
            call TIMER

        ANIM_APAGAR_ED:
            stwio zero, 0(r12)

        beq r8, zero, END_ANIMATION  
        addi r8, r8, -1
        br ANIM_ACENDER_ED

END_ANIMATION:
        
    /* EPÍLOGO */   
    ldw r13, 0(sp)          
    ldw r4, 4(sp)                      /* pop the stack frame */
    ldw r5, 8(sp)
    addi sp, sp, 4                     /* update stack poiter */
    
    ret






