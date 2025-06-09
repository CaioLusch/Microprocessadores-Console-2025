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
    r5: usado em subrotinas
    r6: UART port 
    r7: endereço de BUFFER_COMMAND
    r8: ininicalmente, contem a string padrao pedindo para inserir um comando
    r9: endereço de enter
    r10: valores de comparacao para os condicionais para verificar qual a instrução a ser executada
    r11: valor contido no endereço atual de BUFFER_COMMAND
*/


.equ UART, 0x10001000

.global _start
_start:

movia sp, 0x100000                    /* stack starts from highest memory address in SDRAM */
movia r6, UART                        /* move the uart adress into r6 */
movia r8, TEXT_STRING

INIT:
    
    ldb r5, 0(r8)                       /* load the bitwise string into r5 */
    beq r5, zero, END_INIT              /* verify if the bit written of the string is 0 (string final) */
    call PUT_JTAG                       /* go to the write subroutine (PUT_JTAG) in the terminal */
    addi r8, r8, 1                      /* update the reading to the next char of the string */
    
    br INIT

END_INIT:

READ_POLL:
    call GET_JTAG                       /* chamar a funcao para escrever no buffer a entrafa desejada */
    movia r7, BUFFER_COMMAND            /* endereço do buffer */
    ldb r11, (r7)
    
    addi r10, r0, 0 
    beq r11, r10, LED
    
    addi r10, r10, 1
    beq r11, r10, ANIMACAO
    
    addi r10, r10, 1
    beq r11, r10, CRONOMETRO
    

ANIMACAO:
    call SUB_ANIMACAO    
CRONOMETRO:
    call SUB_CRONOMETRO
LED:
    call SUB_LED

END:
br END                              /* end the program */


.data
TEXT_STRING:
    .asciz "\n 00 XX - Acender xx-ésimo LED \n
               01 XX - Apagar xx-ésimo LED  \n
               10    - Animação com leds dada pelo estado da chave SW0 \n
               11    - Para a animação do LED \n
               20    - Inicia crônometro de segundos \n
               21    - cancela cronometro \n
               Entre com o comando:\n"

.global BUFFER_COMMAND

BUFFER_COMMAND:                            /* buffer para armazenar as instruções */
.skip 100


