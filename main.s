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

.equ UART, 0x10001000

.global _start
_start:

movia sp, 0x007FFFFC                  /* stack starts from highest memory address in SDRAM */
movia r6, UART

/* print a text string */

movia r8, TEXT_STRING

LOOP:
    
    ldb r5, 0(r8)
    beq r5, zero, END       /* string is null-terminated */
    call PUT_JTAG
    addi r8, r8, 1
    
    br LOOP

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
ldw r4, 0(sp)
addi sp, sp, 4
ret


END:
br END


.data
TEXT_STRING:
    .asciz "\nEntre com o comando:"
