.equ TIMER_BASE, 0x10002000
.equ PUSHBUTTON_BASE, 0x10000050
.equ TIMER_IRQ_MASK, 0b01  # IRQ 0
.equ KEY_IRQ_MASK,   0b10  # IRQ 1

.global TICK_COUNTER
TICK_COUNTER:
    .word 0

.org    0x20
.global RTI
RTI:
    /* PRÓLOGO */
    subi sp, sp, 44
    stw ra, 0(sp); stw r4, 4(sp); stw r5, 8(sp); stw r6, 12(sp); stw r7, 16(sp)
    stw r8, 20(sp); stw r10, 24(sp); stw r11, 28(sp); stw r12, 32(sp); stw r13, 36(sp)
    stw et, 40(sp)

    rdctl et, ipending
    beq et, r0, END_RTI
    subi ea, ea, 4

    # Verifica se a interrupção é do Timer (IRQ 0)
    andi r10, et, TIMER_IRQ_MASK
    bne r10, r0, HANDLE_TIMER

    # Verifica se a interrupção é dos Botões (IRQ 1)
    andi r10, et, KEY_IRQ_MASK
    bne r10, r0, HANDLE_KEY

    br END_RTI

HANDLE_TIMER:
    movia r10, TIMER_BASE
    stwio r0, 0(r10)

    # Verifica a flag de animação. Se estiver ativa, executa a animação.
    movia r10, FLAG_ANIMACAO
    ldw r11, 0(r10)
    beq r11, r0, CHECK_CRONO # Se a flag de animação for 0, pula direto para a verificação do cronômetro.
    
    # Se a flag for 1, executa a animação e DEPOIS continua para o cronômetro.
    call CALL_ANIMATION
    
CHECK_CRONO:
    # Esta seção será executada em ambos os casos:
    # 1. Se a animação estiver desligada (devido ao 'beq' acima).
    # 2. Se a animação estiver ligada e já tiver sido executada (por "fall-through").

    movia r10, FLAG_CRONOMETRO
    ldw r11, 0(r10)
    beq r11, r0, END_RTI # Se o cronômetro estiver desligado, encerra tudo.

    movia r10, CRONOMETRO_PAUSA
    ldw r11, 0(r10)
    bne r11, r0, END_RTI # Se estiver pausado, encerra.

    # Lógica do Tick para contar 1 segundo
    movia r10, TICK_COUNTER
    ldw r11, 0(r10)
    addi r11, r11, 1
    
    movi r12, 5
    blt r11, r12, SAVE_TICK
    
    stw r0, 0(r10)
    call CONTA_TEMPO
    call DISPLAY_TEMPO
    br END_RTI

SAVE_TICK:
    stw r11, 0(r10)
    br END_RTI

HANDLE_KEY:
    movia r10, PUSHBUTTON_BASE
    stwio r0, 12(r10)

    movia r10, CRONOMETRO_PAUSA
    ldw r11, 0(r10)
    xori r11, r11, 1
    stw r11, 0(r10)
    br END_RTI

END_RTI:
    /* EPÍLOGO */
    ldw ra, 0(sp); ldw r4, 4(sp); ldw r5, 8(sp); ldw r6, 12(sp); ldw r7, 16(sp)
    ldw r8, 20(sp); ldw r10, 24(sp); ldw r11, 28(sp); ldw r12, 32(sp); ldw r13, 36(sp)
    ldw et, 40(sp)
    addi sp, sp, 44
    eret