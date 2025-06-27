.equ SEVEN_SEG_BASE, 0x10000020                  /* end display de 7 segmentos */

# Código para apagar o display (valor para quando o cronômetro está zerado e desligado)
.equ DISPLAY_OFF, 0xFFFFFFFF
SEVEN_SEG_CODES:
    .byte 0x3F  # 0
    .byte 0x06  # 1
    .byte 0x5B  # 2
    .byte 0x4F  # 3
    .byte 0x66  # 4
    .byte 0x6D  # 5
    .byte 0x7D  # 6
    .byte 0x07  # 7
    .byte 0x7F  # 8
    .byte 0x67  # 9

.global CONTA_TEMPO
CONTA_TEMPO:
    # Esta rotina incrementa o tempo em 1 segundo.
    # PRÓLOGO
    subi sp, sp, 12
    stw r4, 0(sp)
    stw r5, 4(sp)
    stw r8, 8(sp)

    # Carrega os ponteiros para as variáveis de tempo
    movia r8, TEMPO_SEG_UNI

    # Incrementa a unidade do segundo
    ldw r4, 0(r8)
    addi r4, r4, 1

    # Verifica se chegou em 10
    movi r5, 10
    bne r4, r5, SAVE_SEG_UNI # Se não for 10, apenas salva

    # Se chegou, zera a unidade e incrementa a dezena do segundo
    mov r4, r0 # Zera a unidade
    stw r4, 0(r8)
    
    # Incrementa a dezena do segundo
    movia r8, TEMPO_SEG_DEZ
    ldw r4, 0(r8)
    addi r4, r4, 1

    # Verifica se chegou em 6 (60 segundos)
    movi r5, 6
    bne r4, r5, SAVE_SEG_DEZ # Se não for 6, apenas salva

    # Se chegou, zera a dezena e incrementa a unidade do minuto
    mov r4, r0
    stw r4, 0(r8)
    
    # Incrementa a unidade do minuto
    movia r8, TEMPO_MIN_UNI
    ldw r4, 0(r8)
    addi r4, r4, 1
    
    # Verifica se chegou em 10
    movi r5, 10
    bne r4, r5, SAVE_MIN_UNI # Se não for 10, apenas salva
    
    # Se chegou, zera a unidade e incrementa a dezena do minuto
    mov r4, r0
    stw r4, 0(r8)

    movia r8, TEMPO_MIN_DEZ
    ldw r4, 0(r8)
    addi r4, r4, 1
    # Aqui não verificamos o limite de 60 minutos, mas poderia ser adicionado

    SAVE_MIN_DEZ:
        stw r4, 0(r8)
        br END_CONTA_TEMPO
    SAVE_MIN_UNI:
        stw r4, 0(r8)
        br END_CONTA_TEMPO
    SAVE_SEG_DEZ:
        stw r4, 0(r8)
        br END_CONTA_TEMPO
    SAVE_SEG_UNI:
        stw r4, 0(r8)

    END_CONTA_TEMPO:
        # EPÍLOGO
        ldw r4, 0(sp)
        ldw r5, 4(sp)
        ldw r8, 8(sp)
        addi sp, sp, 12
ret

.global DISPLAY_TEMPO
DISPLAY_TEMPO:
    # Esta rotina pega os 4 dígitos do tempo e os mostra nos displays.
    # PRÓLOGO
    subi sp, sp, 20
    stw r4, 0(sp)
    stw r5, 4(sp)
    stw r8, 8(sp)
    stw r9, 12(sp)
    stw r10, 16(sp)

    # Carrega os 4 dígitos da memória
    movia r8, TEMPO_MIN_DEZ
    ldw r4, 0(r8)                                   # r4 = Dezena do Minuto
    movia r8, TEMPO_MIN_UNI
    ldw r5, 0(r8)                                   # r5 = Unidade do Minuto
    movia r8, TEMPO_SEG_DEZ
    ldw r8, 0(r8)                                   # r8 = Dezena do Segundo
    movia r9, TEMPO_SEG_UNI
    ldw r9, 0(r9)                                   # r9 = Unidade do Segundo

    # Converte cada dígito para o código do display de 7 segmentos
    movia r10, SEVEN_SEG_CODES
    add r4, r10, r4
    ldb r4, 0(r4)                                   # r4 = Código para Dezena Minuto

    add r5, r10, r5
    ldb r5, 0(r5)                                   # r5 = Código para Unidade Minuto

    add r8, r10, r8
    ldb r8, 0(r8)                                   # r8 = Código para Dezena Segundo

    add r9, r10, r9
    ldb r9, 0(r9)                                   # r9 = Código para Unidade Segundo

    # Monta a palavra de 32 bits para enviar ao hardware
    # Formato: [Disp3 (MinDez)] [Disp2 (MinUni)] [Disp1 (SegDez)] [Disp0 (SegUni)]
    slli r8, r8, 8                                  # Desloca SegDez
    slli r5, r5, 16                                 # Desloca MinUni
    slli r4, r4, 24                                 #  Desloca MinDez
    
    or r9, r9, r8
    or r9, r9, r5
    or r9, r9, r4

    # Escreve o valor final nos displays de 7 segmentos
    movia r10, SEVEN_SEG_BASE
    stwio r9, 0(r10)
    
    # EPÍLOGO
    ldw r4, 0(sp)
    ldw r5, 4(sp)
    ldw r8, 8(sp)
    ldw r9, 12(sp)
    ldw r10, 16(sp)
    addi sp, sp, 20
ret

.global CANCELA_CRONOMETRO
CANCELA_CRONOMETRO:
    # Zera todas as flags e variáveis do cronômetro
    movia r4, FLAG_CRONOMETRO
    stw r0, 0(r4)
    movia r4, CRONOMETRO_PAUSA
    stw r0, 0(r4)
    movia r4, TEMPO_MIN_DEZ
    stw r0, 0(r4)
    movia r4, TEMPO_MIN_UNI
    stw r0, 0(r4)
    movia r4, TEMPO_SEG_DEZ
    stw r0, 0(r4)
    movia r4, TEMPO_SEG_UNI
    stw r0, 0(r4)
    
    # Apaga os displays
    movia r4, SEVEN_SEG_BASE
    movi r5, DISPLAY_OFF
    stwio r5, 0(r4)
ret