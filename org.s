.equ TIMER_BASE, 0x10002000
.equ TIMER_IRQ_MASK, 1      # Máscara para a IRQ 0

.org    0x20
.global RTI
RTI:
    /* PRÓLOGO - Salva um conjunto abrangente de registradores para segurança */
    subi sp, sp, 44
    stw ra, 0(sp)
    stw r4, 4(sp)
    stw r5, 8(sp)
    stw r6, 12(sp)
    stw r7, 16(sp)
    stw r8, 20(sp)
    stw r10, 24(sp)
    stw r11, 28(sp)
    stw r12, 32(sp)
    stw r13, 36(sp)
    stw et, 40(sp) # Salva 'et' pois rdctl o modifica

    /* Lê as interrupções pendentes */
    rdctl et, ipending
    beq et, r0, END_RTI      # Se não há interrupções, encerra

    subi ea, ea, 4           # Corrige o endereço de retorno para interrupção de hardware

    # --- Início do Tratamento de Interrupções ---

    # Verifica se a interrupção do Timer (IRQ 0) está ativa
    andi r10, et, TIMER_IRQ_MASK
    beq r10, r0, END_RTI     # Se não for o timer, encerra (poderia checar outras IRQs aqui)

    # Se chegou aqui, é o timer.
    # 1. Limpa a flag de interrupção do hardware do timer.
    movia r10, TIMER_BASE
    stwio r0, 0(r10)

    # 2. Verifica a flag de animação que está na MEMÓRIA.
    movia r10, FLAG_ANIMACAO # Carrega o endereço da flag
    ldw r11, 0(r10)          # Carrega o valor da flag (0 ou 1) para r11
    beq r11, r0, END_RTI     # Se a flag for 0, não faz nada e encerra o RTI

    # 3. Se a flag for 1, chama a rotina de animação.
    call CALL_ANIMATION

    # --- Fim do Tratamento de Interrupções ---

END_RTI:
    /* EPÍLOGO - Restaura todos os registradores na ordem inversa */
    ldw ra, 0(sp)
    ldw r4, 4(sp)
    ldw r5, 8(sp)
    ldw r6, 12(sp)
    ldw r7, 16(sp)
    ldw r8, 20(sp)
    ldw r10, 24(sp)
    ldw r11, 28(sp)
    ldw r12, 32(sp)
    ldw r13, 36(sp)
    ldw et, 40(sp)
    addi sp, sp, 44

    eret                     # Retorna da interrupção