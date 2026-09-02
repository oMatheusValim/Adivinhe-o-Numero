# Jogo de advinhar um número em Assembly RISC-V

> **SSC0902 – Organização e Arquitetura de Computadores**  
> Prof. Dra. Sarita Mazzini Bruschi — ICMC/USP

---

## Integrantes

| Nome | Nº USP |
|------|--------|
| *Arthur Silva de Albuquerque* | *17078155* |
| *Bruno Lopes de Almeida Zuffo* | *15444031* |
| *Cody Stefano Barham Setti* | *4856322* |
| *Matheus Valim Nogueira* | *15746323* |

---

## Descrição do Projeto
O trabalho consistiu na implementação do jogo "Adivinhe o Número" em Assembly
RISC-V (RV32IM), executado no simulador RARS. O programa sorteia um número
entre 1 e 100 usando um Gerador Congruente Linear (LCG) implementado do zero,
recebe palpites do jogador em um laço de interação, fornece retorno (muito
alto / muito baixo / correto) e, ao final, exibe o total de tentativas e o
histórico completo dos palpites, armazenados em uma lista ligada alocada
dinamicamente na heap.

## Estrutura do Projeto
```
├── jogo.s
├── Readme.md
└── Relatorio.md
``` 

## Estrutura do código

O código foi organizado em funções, cada uma com uma responsabilidade única,
seguindo a convenção de chamada RISC-V (argumentos e retornos em `a0`-`a7`,
registradores `s0`-`s11` preservados entre chamadas, `ra` salvo/restaurado
quando há chamadas aninhadas):

- **`main`**: orquestra o fluxo do jogo (inicialização, laço principal,
  finalização).
- **`gera_aleatorio`**: implementa o LCG (`X(n+1) = (a*X(n)+c) mod m`) e
  reduz o resultado ao intervalo [1, 100] com a operação `remu`.
- **`cria_no`**: aloca 8 bytes na heap via `ecall 9` (sbrk) e monta um nó da
  lista ligada (valor + ponteiro `próximo`).
- **`imprime_lista`**: percorre a lista ligada do início ao fim, imprimindo
  cada tentativa registrada.
- **`imprime_string`** / **`imprime_inteiro`**: encapsulam as `ecall`s de
  impressão, evitando repetição de código.

## Compilação e execução

## Instruções de Execução

### Pré-requisitos

O programa foi escrito em Assembly RISC-V (RV32IM) e usa as *environment calls*
(`ecall`) padrão do simulador **RARS** (RISC-V Assembler and Runtime Simulator).

1. Baixe o RARS (arquivo `.jar`) em: https://github.com/TheThirdOne/rars/releases
2. É necessário ter o Java instalado (`java -version` para conferir).

### Como executar

#### Opção A — Interface gráfica do RARS
1. Abra o RARS: `java -jar rars.jar`
2. Vá em **File → Open** e selecione o arquivo `jogo.s`.
3. Clique em **Assemble** (F3) para montar o programa.
4. Clique em **Run** (F5) para executar.
5. Digite seus palpites no console do RARS quando solicitado.

#### Opção B — Linha de comando
```bash
java -jar rars.jar jogo.s
```
O jogo iniciará automaticamente no terminal, pedindo os palpites do jogador.

### Como jogar

1. O programa exibirá uma mensagem de boas-vindas.
2. Digite um número entre 1 e 100 quando solicitado ("Digite seu palpite:").
3. O programa informará se o palpite foi muito alto, muito baixo ou correto.
4. Repita até acertar o número secreto.
5. Ao acertar, o programa exibirá:
   - Uma mensagem de parabéns;
   - O número total de tentativas realizadas;
   - O histórico completo de todos os palpites digitados, na ordem em que
     foram feitos (obtido percorrendo a lista ligada alocada na heap).

### Observações técnicas

- O número secreto é gerado por um **Gerador Congruente Linear (LCG)**
  implementado manualmente (função `gera_aleatorio`), usando o relógio do
  sistema (`ecall 30`) como semente inicial — portanto, o número sorteado
  muda a cada execução.
- Cada tentativa do jogador é armazenada em um nó de uma **lista ligada**,
  alocado dinamicamente na heap através da chamada de sistema `sbrk`
  (`ecall 9`). A pilha (stack) é usada apenas para salvar/restaurar
  registradores nas chamadas de função, nunca para os dados da lista.

