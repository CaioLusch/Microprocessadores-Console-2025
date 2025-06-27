/*
    import led.s
    import animacao.s
    import cronometro.s

    o arquivo main é o responsável por lidar com interrupções, receber e tratar os comandos do usuário
    ex: Se o usuario digitar o comando correpondente a ligar os Leds, chamará o arquivo que lida com isso

    while(1):
        
        comando = LER_UART() -> fazer polling até o usuário apertar enter e pegar no buffer

        switch(comando[0]):
            case 0:
                call led.s
            case 1:
                call animacao.s
            case 2:
                call cronometro.s
    LER_UART:
        command_pointer = endereço de comando
        
        POLLING:
            
            char <= le UART
            enquanto char for invalido, volta para POLLING
            se char == ENTER, sai
            *command_pointer = char
            avança command_pointer
            
            br POLLING
    COMMAND:
    .skip 100 (buffer para armazenar um local de memória para os comandos)

    TEXT_STRING:
    .asciz "\nJTAG UART example code\n>"


    QUESTÕES:
    - o que acontece com o cronometro quando é cancelado? Ele zera assim que cancela? ou ela "pausa"?
    - o que deve acontecer caso exista um led aceso e um comando de animacao seja entrado: 
        1. perder o estado do led aceso 
        ou 
        2. restaura-lo assim que a animacão for cancelada?
*/

/*
    r4: flag animacao
    r5: usado em subrotinas
    r6: UART port 
    r7: endereço de BUFFER_COMMAND
    r8: ininicalmente, contem a string padrao pedindo para inserir um comando
    r9: endereço de enter
    r10: valores de comparacao para os condicionais para verificar qual a instrução a ser executada
    r11: valor contido no endereço atual de BUFFER_COMMAND
    r18: flag animacao
    r19: flag cronometro
*/


.equ UART, 0x10001000
.equ KEY_ONE, 0x10000050
.global _start
_start:

movia sp, 0x100000                    /* stack starts from highest memory address in SDRAM */
movia r6, UART                        /* move the uart adress into r6 */
movia r8, TEXT_STRING
movia r12, 0x10000000               /* endereço do led vermelho (usado como referencial)*/

INIT:
    
    ldb r5, 0(r8)                       /* load the bitwise string into r5 */
    beq r5, zero, END_INIT              /* verify if the bit written of the string is 0 (string final) */
    call PUT_JTAG                       /* go to the write subroutine (PUT_JTAG) in the terminal */
    addi r8, r8, 1                      /* update the reading to the next char of the string */
    
    br INIT

END_INIT:

CONFIG:
    /* Zera a flag de animação na memória ao iniciar */
    movia r4, FLAG_ANIMACAO
    stw r0, 0(r4)

    movia r4, LEDS_MANUAIS_STATE
    stw r0, 0(r4)

    call CANCELA_CRONOMETRO


    # Habilita interrupções globais (IRQ 0 e IRQ 1)
    movi r15, 0x1                  # Global enable
    wrctl status, r15

    call SET_TIMER

    # Habilita interrupção do Pushbutton KEY1 (IRQ 1)
    movia r4, KEY_ONE
    movi r5, 0b0010 # Habilita interrupção apenas para KEY1
    stwio r5, 8(r4)  # Escreve no registrador de máscara de interrupção (offset 8)
    
    /* Habilitar interrupções no processador Nios II*/
    movi et, 1
    wrctl ienable, et

READ_POLL:
    call GET_JTAG                       /* chamar a funcao para escrever no buffer a entrada desejada */
    movia r7, BUFFER_COMMAND            /* endereço do buffer */
    ldb r11, (r7)
    
    addi r10, r0, 0 
    beq r11, r10, LED
    
    addi r10, r10, 1
    beq r11, r10, ANIMACAO
    
    addi r10, r10, 1
    beq r11, r10, CRONOMETRO
    

ANIMACAO:                               /* tudo que essas rótulos vao fazer é modificar as vars para habilitar que a interrupção realize as modificaçoes */
    ldb r5, 1(r7)                       /* Lê o segundo dígito do comando */
    beq r5, r0, START_ANIM              /* Se for '0', inicia a animação */
    movi r10, 1
    beq r5, r10, STOP_ANIM              /* Se for '1', para a animação */
    br READ_POLL                        /* Se chegou aqui é pq o comando é invalido */

    START_ANIM:
        movia r4, FLAG_ANIMACAO
        movi r5, 1
        stw r5, 0(r4)

        movia r4, ANIMATION_COUNTER         # Endereço do nosso contador
        stw r0, 0(r4)                       # Zera o contador, para a animação começar do LED 0
        br READ_POLL                        # Voltar para inserir outro comando

    STOP_ANIM:
        movia r4, FLAG_ANIMACAO
        stw r0, 0(r4)
        br READ_POLL

CRONOMETRO:
    ldb r5, 1(r7)
    beq r5, r0, START_CRONOMETRO
    movi r10, 1
    beq r5, r10, STOP_CRONOMETRO
    br READ_POLL

    START_CRONOMETRO:
        movia r4, FLAG_CRONOMETRO
        movi r5, 1
        stw r5, 0(r4)
        br READ_POLL

    STOP_CRONOMETRO:
        call CANCELA_CRONOMETRO
        br READ_POLL

LED:                                   /* Exceto LED, porque nao usa o timer (uhull), pode permanecer assim mesmo */
    call CALL_LED
    br READ_POLL

END:
br END                              /* end the program */


.global FLAG_ANIMACAO
FLAG_ANIMACAO:
.word 0

.global BUFFER_COMMAND
BUFFER_COMMAND:                            /* buffer para armazenar as instruções */
.skip 100

.align 2
.global LEDS_MANUAIS_STATE
LEDS_MANUAIS_STATE:
    .word 0

.global FLAG_CRONOMETRO
FLAG_CRONOMETRO:
    .word 0
.global CRONOMETRO_PAUSA
CRONOMETRO_PAUSA:
    .word 0
.global TEMPO_MIN_DEZ
TEMPO_MIN_DEZ:
    .word 0
.global TEMPO_MIN_UNI
TEMPO_MIN_UNI:
    .word 0
.global TEMPO_SEG_DEZ
TEMPO_SEG_DEZ:
    .word 0
.global TEMPO_SEG_UNI
TEMPO_SEG_UNI:
    .word 0

TEXT_STRING:
    .asciz "\n 00 XX: Acender xx-esimo LED \n 01 XX: Apagar xx-esimo LED \n 10: animacao com leds com SW0 \n 11: Para a animacao do LED \n 20: Inicia cronometro de segundos \n 21: cancela cronometro \n Entre com o comando:\n"

