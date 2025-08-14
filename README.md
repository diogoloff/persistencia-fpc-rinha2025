# 🥊 Persistencia para Rinha de Backend - 2025

Projeto desenvolvido para participar da [Rinha de Backend 2025](https://github.com/zanfranceschi/rinha-de-backend-2025), utilizando Free Pascal.

## 🚀 Tecnologias Utilizadas

- **Linguagem:** Free Pascal  
- **Framework:** mORMot2  

## 📄 Como Rodar

Clone o repositório:
   ```bash
   git clone https://github.com/diogoloff/persistencia-fpc-rinha2025
```

## Dificuldades enfrentadas

Durante a Rinha, minha ideia inicial era utilizar persistência em Firebird, mas acabei enfrentando limitações de processamento.

Quanto à isto, criei um sistema em memória com inclusão e leitura de dados próprio. Avaliei o uso do Redis, mas tanto em Delphi como em FPC não existe nativo. Encontrei apenas uma biblioteca antiga no GitHub, compatível com uma versão desatualizada do Redis. Apesar de ter tentado integrá-la, enfrentei sérios problemas de concorrência e inconsistência nos dados. Diante disso, desenvolvi uma solução própria que se mostrou mais estável e eficiente para o desafio.
