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
    subi sp, sp, 20                     /* Mais espaço para salvar registradores */
    stw ra, 0(sp)
    stw r4, 4(sp)
    stw r5, 8(sp)
    stw r8, 12(sp)
    stw r10, 16(sp)

    movia r12, 0x10000000               /* endereço do led vermelho */

    stwio zero, 0(r12)                   /* apaga todos os leds antes de ascender o prox */

    /* pegar da memoria qual led deve acender */
    movia r8, ANIMATION_COUNTER         /* r8 = endereço da variavel*/
    ldw r8, 0(r8)                       /* r8 = valor do contador (número do LED) */

    /* Cria a máscara para acender o LED correto: 1 << r8 (deslocar o '1' em um numero de casas igual ao valor contido em r8) */
    movi r4, 1
    sll r4, r4, r8
    stwio r4, 0(r12)                    /* Acende o led da posição */

    /* alavanca para decidir a direção */
    ldwio r5, SWITCH(r12)
    andi r5, r5, 1                      /* Isola o bit 0 da alavanca */

    beq r5, r0, DIR_ESQ_STEP            /* Se alavanca = 0, (17 <- 0) */
    br ESQ_DIR_STEP                     /* Se alavanca = 1, (17 -> 0) */

    DIR_ESQ_STEP:
        addi r8, r8, 1                      /* Incrementa o contador do LED */
        movi r10, 18
        bne r8, r10, SAVE_STATE             /* Se não chegou em 18, apenas salva */
        mov r8, r0                          /* Se chegou em 18, volta para 0 */
        
        br SAVE_STATE

    ESQ_DIR_STEP:
        subi r8, r8, 1                      /* Decrementa o contador do LED */
        movi r10, -1
        bne r8, r10, SAVE_STATE             /* Se não chegou em -1, apenas salva */
        movi r8, 17                         /* Se chegou em -1, volta para 17 */
        
        br SAVE_STATE

SAVE_STATE:
    /* Salva o novo estado (próximo LED a ser aceso) na memória */
    movia r4, ANIMATION_COUNTER
    stw r8, 0(r4)

END_ANIMATION:
    
    /* EPÍLOGO */   
    ldw ra, 0(sp)
    ldw r4, 4(sp)
    ldw r5, 8(sp)
    ldw r8, 12(sp)
    ldw r10, 16(sp)
    addi sp, sp, 20
    
    ret

.global ANIMATION_COUNTER    /* variavel em memória para armazenar qual led deve ser aceso*/
ANIMATION_COUNTER:
.word 0






