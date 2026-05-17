# 🏆 Protocolo de Fidelidade Web3

> MVP de protocolo descentralizado desenvolvido como projeto final da disciplina Web 3.0 — Residência em TIC 29.

---

## 📋 Sobre o Projeto

Programas de fidelidade tradicionais são centralizados — a empresa pode alterar ou cancelar seus pontos a qualquer momento. Este protocolo resolve esse problema garantindo que o usuário seja **dono real** das suas recompensas por meio de smart contracts imutáveis e transparentes na blockchain Ethereum.

---

## 🏗️ Arquitetura

Usuário
├── FidelityToken (ERC-20) → token de recompensa (FDL)
├── FidelityNFT (ERC-721) → distintivo de membro
└── Governance (DAO) → votação de parâmetros
│
Staking
├── acumula recompensas
├── integra Chainlink (ETH/USD)
└── concede NFT automaticamente

**Cadeia de controle (ownership):**

Você → Governance → Staking → FidelityToken
→ FidelityNFT

---

## 📦 Contratos

| Contrato      | Padrão  | Endereço (Sepolia)                           |
| ------------- | ------- | -------------------------------------------- |
| FidelityToken | ERC-20  | `0x719e6C427DA1DBFF7800DF3B2c1cD59b88e1fb13` |
| FidelityNFT   | ERC-721 | `0x815AF36fbC0D24c5dFC86eCc3A3881255A89ACAB` |
| Staking       | Custom  | `0x18fB769936fF3D9F65B47D4F003A537203849851` |
| Governance    | DAO     | `0x24A00a58c0eBf54873F4D6594f1892b1e3B696E4` |

🔗 Verificar na Sepolia: https://sepolia.etherscan.io

---

## 🚀 Como Usar

### Pré-requisitos

- Extensão [MetaMask](https://metamask.io/) instalada no browser
- ETH de teste na Sepolia — obtenha em [sepoliafaucet.com](https://sepoliafaucet.com)

### Executar a interface

1. Clone o repositório:

bash
git clone https://github.com/Cabral369/smart_contract
cd smart_contract

2. Abra o arquivo `index.html` diretamente no browser:

Clique duas vezes no index.html
ou arraste para o browser

3. Clique em **Conectar Carteira** e autorize a MetaMask

4. Certifique-se de estar na rede **Sepolia** na MetaMask

> Nenhuma instalação de dependências necessária — o ethers.js é carregado via CDN.

---

## 🔧 Funcionalidades

### Token ERC-20 (FidelityToken)

- Supply inicial de 1.000.000 FDL
- Mint controlado pelo contrato Staking
- Função burn para resgate externo

### NFT ERC-721 (FidelityNFT)

- 1 NFT por usuário (distintivo único)
- Concedido automaticamente ao acumular 500 FDL em recompensas
- Não duplicável

### Staking

- Deposite FDL e acumule recompensas por tempo
- Multiplicador dinâmico via Chainlink ETH/USD:
  - ETH > $3.000 → recompensa 2x
  - ETH > $2.000 → recompensa 1.5x
  - Demais → recompensa 1x
- NFT concedido automaticamente ao resgatar 500+ FDL

### Governance (DAO)

- Crie propostas para alterar parâmetros do protocolo
- Poder de voto proporcional ao saldo de FDL
- Quórum mínimo de 100 FDL para aprovação
- Execução automática da decisão no Staking

---

## 🔐 Segurança

| Mecanismo         | Aplicação                                                  |
| ----------------- | ---------------------------------------------------------- |
| `ReentrancyGuard` | Proteção contra ataques de reentrancy nas funções de saque |
| `require()`       | Validações em todas as funções críticas                    |
| `onlyOwner`       | Restringe mint, NFT e ajuste de parâmetros                 |
| Solidity `^0.8.x` | Proteção nativa contra overflow/underflow                  |
| Mapping de votos  | Impede voto duplo na DAO                                   |

---

## 📁 Estrutura de Arquivos

/
├── FidelityToken.sol # Token ERC-20 de recompensa
├── FidelityNFT.sol # NFT ERC-721 de fidelidade
├── Staking.sol # Contrato central de staking
├── Governance.sol # DAO simplificada
├── index.html # Interface Web3 (ethers.js via CDN)
└── README.md

---

## 🌐 Oráculo Chainlink

- **Feed:** ETH/USD
- **Rede:** Sepolia
- **Endereço:** `0x694AA1769357215DE4FAC081bf1f309aDC325306`

---

## 📚 Tecnologias

- [Solidity](https://soliditylang.org/) `^0.8.0`
- [OpenZeppelin Contracts](https://openzeppelin.com/contracts/)
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- [ethers.js](https://docs.ethers.org/) `v6` via CDN
- [Remix IDE](https://remix.ethereum.org/)
- [MetaMask](https://metamask.io/)

---

## 👨‍💻 Autor

Desenvolvido como projeto final da disciplina **Web 3.0 — Residência em TIC 29**
