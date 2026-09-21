# Convencao de chamada adotada:
#   a0-a7 : passa argumentos para a função e ecall, e também carrega valores de retorno 
#   t0-t6 : registradores temporarios, pode ser sobrescritos por qualquer função chamada
#   s0-s11: registradores salvos, vai ser um backup do valor antigo da pilha e pode ser utilizado para restaurar
#   ra    : endereco de retorno, gravado automaticamente pela jal 
#   sp    : ponteiro de pilha (usado apenas para salvar/restaurar registradores,
#           nunca para armazenar os nos da lista ligada)

# o asciz é para que exiba a mensagem e dê como ação terminada. Isso acontece por causa do "z" no fim, que significa 'zero-terminated', colocando um \0 no fim.
.data
    # Mensagens do jogo
    msg_boas_vindas:      .asciz "\n Bem-vindo ao jogo ADIVINHE O NUMERO!\n\nO computador escolheu um numero entre 1 e 100.\nTente adivinhar em quantas tentativas conseguir!\n\n"
    msg_prompt:            .asciz "Digite seu palpite: "
    msg_muito_alto:        .asciz ">> Muito alto! Tente novamente.\n\n"
    msg_muito_baixo:       .asciz ">> Muito baixo! Tente novamente.\n\n"
    msg_correto:           .asciz "\n\n Parabens! Voce acertou o numero!\n\n"
    msg_tentativas_qtd:    .asciz "Numero de tentativas: "
    msg_lista_tentativas:  .asciz "Historico de tentativas: "
    msg_separador:         .asciz ", "
    msg_newline:           .asciz "\n"

.text
.globl main

main:
    # reserva espaco na pilha para os registradores salvos
    addi    sp, sp, -32     # a pilha cresce para baixo, abrindo 32 bytes de espaço no topo da pilha 
    # sw salva um registrador nesse espaço
    sw      ra, 28(sp)       # para saber onde retornar ao salvar outras funções
    sw      s0, 24(sp)       # s0 = numero secreto sorteado
    sw      s1, 20(sp)       # s1 = ponteiro para a cabeca da lista (head)
    sw      s2, 16(sp)       # s2 = ponteiro para a cauda da lista (tail)
    sw      s3, 12(sp)       # s3 = contador de tentativas
    sw      s4, 8(sp)        # s4 = palpite atual do jogador

    # Exibe a mensagem de boas-vindas e as instrucoes
    la      a0, msg_boas_vindas     # coloca em a0 o endereço da mensagem de boas vindas
    jal     imprime_string          # vai para a função e grava o endereço de retorno em ra

    # Obtem uma semente a partir do relogio do sistema
    li      a7, 30           # ecall 30: retorna o tempo atual (a0 = parte baixa em ms e a1 = parte alta)
    ecall                    # dispara a chamada para o sistema
    mv      t0, a0           # copia o valor de a0 para t0 para usar como valor temporário para passar adiante 

    # Gera o numero secreto (entre 1 e 100) usando o LCG
    mv      a0, t0           # passa t0 como argumento para gerar o número aleatório
    jal     gera_aleatorio   # gera o valor aleatorio
    mv      s0, a0           # guarda em s0 o número aleatório

    # Inicializa a lista ligada de tentativas (vazia)
    li      s1, 0            # head = NULL
    li      s2, 0            # tail = NULL
    li      s3, 0            # contador de tentativas = 0

loop_jogo:
    la      a0, msg_prompt   # exibe a mensagem de inicio do jogo
    jal     imprime_string

    li      a7, 5            # a7 = 5 é um syscall que le um numero inteiro do teclado, e guarda em a0
    ecall
    mv      s4, a0           # guarda o valor de a0 em s4, para não perder informação nas próximas chamadas

    # Cria um novo no na heap contendo o palpite
    mv      a0, s4           # passa o s4 como argumento
    jal     cria_no          # cria o nó
    mv      t1, a0           # t1 = endereco do novo nó

    addi    s3, s3, 1        # incrementa o contador de tentativas

    # Insere o novo nó no final da lista ligada (ordem cronologica)
    beq     s1, zero, lista_vazia       # se head é null, a lista está vazia, e salta para o caso especial 
    sw      t1, 4(s2)        # grava o endereço do nó no campo next que atualmente é a tail, pendurando o nó no fim da lista
    mv      s2, t1           # Atualiza a tail para que aponte para o novo nó
    j       compara_palpite  
lista_vazia:
    mv      s1, t1           # head = novo no
    mv      s2, t1           # tail = novo no

compara_palpite:
    # Compara o palpite do jogador com o numero secreto
    blt     s4, s0, palpite_baixo
    bgt     s4, s0, palpite_alto
    j       acertou

palpite_baixo:
    la      a0, msg_muito_baixo
    jal     imprime_string
    j       loop_jogo

palpite_alto:
    la      a0, msg_muito_alto
    jal     imprime_string
    j       loop_jogo

acertou:
    # Exibe a mensagem de parabens
    la      a0, msg_correto
    jal     imprime_string

    # Exibe o numero total de tentativas realizadas
    la      a0, msg_tentativas_qtd
    jal     imprime_string
    mv      a0, s3
    jal     imprime_inteiro
    la      a0, msg_newline
    jal     imprime_string

    # Percorre a lista ligada ate o fim, imprimindo todas as tentativas
    la      a0, msg_lista_tentativas
    jal     imprime_string
    mv      a0, s1
    jal     imprime_lista
    la      a0, msg_newline
    jal     imprime_string

    # Epilogo: restaura os registradores salvos e desfaz o quadro de pilha
    lw      ra, 28(sp)
    lw      s0, 24(sp)
    lw      s1, 20(sp)
    lw      s2, 16(sp)
    lw      s3, 12(sp)
    lw      s4, 8(sp)
    addi    sp, sp, 32

    li      a7, 10           # ecall 10: encerra o programa
    ecall


# gera_aleatorio: gera um numero pseudoaleatorio entre 1 e 100
#   utilizando o algoritmo de Gerador Congruente Linear (LCG):
#       X(n+1) = (a * X(n) + c) mod m
#   Parametros:
#       a0 = semente (X0)
#   Retorno:
#       a0 = numero pseudoaleatorio no intervalo [1, 100]

gera_aleatorio:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    li      t0, 1103515245   # constante multiplicadora (a)
    li      t1, 12345        # constante aditiva (c)

    mul     t2, a0, t0       # t2 = a * seed
    add     t2, t2, t1       # t2 = (a * seed) + c

    li      t3, 0x7FFFFFFF   # m = 2^31 -> mascara equivalente ao modulo
    and     t2, t2, t3       # t2 = (a*seed + c) mod 2^31

    li      t4, 100
    remu    t5, t2, t4       # t5 = t2 mod 100 -> intervalo [0, 99]
    addi    a0, t5, 1        # a0 = numero no intervalo [1, 100]

    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret

# cria_no: aloca dinamicamente, na heap, um no da lista ligada
#   Estrutura do no (8 bytes):
#       offset 0: valor da tentativa (word, 4 bytes)
#       offset 4: ponteiro para o proximo no (word, 4 bytes)
#   Parametros:
#       a0 = valor a ser armazenado no no (o palpite)
#   Retorno:
#       a0 = endereco do no alocado na heap

cria_no:
    addi    sp, sp, -8
    sw      ra, 4(sp)
    sw      s0, 0(sp)

    mv      s0, a0           # salva o valor do palpite antes da syscall

    li      a0, 8            # solicita 8 bytes de memoria na heap
    li      a7, 9            # ecall 9: sbrk (alocacao dinamica de memoria)
    ecall                    # a0 = endereco do bloco alocado

    sw      s0, 0(a0)        # armazena o valor da tentativa no no
    sw      zero, 4(a0)      # inicializa o ponteiro "proximo" como NULL

    lw      ra, 4(sp)
    lw      s0, 0(sp)
    addi    sp, sp, 8
    ret


# imprime_lista: percorre a lista ligada ate o fim, imprimindo
#   os valores armazenados em cada no, separados por virgula
#   Parametros:
#       a0 = endereco do primeiro no da lista (head)

imprime_lista:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)        # s0 = no atual durante o percurso
    sw      s1, 4(sp)        # s1 = flag indicando se e o primeiro elemento

    mv      s0, a0
    li      s1, 1            # 1 = ainda e o primeiro elemento (sem separador antes)

percorre_lista:
    beq     s0, zero, fim_lista

    beqz    s1, imprime_separador
    li      s1, 0
    j       imprime_valor_no

imprime_separador:
    la      a0, msg_separador
    jal     imprime_string

imprime_valor_no:
    lw      a0, 0(s0)        # carrega o valor armazenado no no atual
    jal     imprime_inteiro

    lw      s0, 4(s0)        # avanca para o proximo no da lista
    j       percorre_lista

fim_lista:
    lw      ra, 12(sp)
    lw      s0, 8(sp)
    lw      s1, 4(sp)
    addi    sp, sp, 16
    ret


# imprime_string: imprime uma string terminada em nulo
#   Parametros:
#       a0 = endereco da string

imprime_string:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    li      a7, 4            # ecall 4: imprime uma string
    ecall

    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret


# imprime_inteiro: imprime um numero inteiro
#   Parametros:
#       a0 = valor inteiro a ser impresso

imprime_inteiro:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    li      a7, 1            # ecall 1: imprime um inteiro
    ecall

    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret