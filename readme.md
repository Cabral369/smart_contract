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

Você → Governance → Staking → FidelityToken → FidelityNFT

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

## 🚀 Como Executar

### Pré-requisitos

- Node.js 18+
- MetaMask com ETH de teste na Sepolia
- Conta Infura (RPC)

### Instalação

bash
git clone https://github.com/seu-usuario/fidelidade-web3
cd fidelidade-web3
npm install ethers

### Configuração

Edite o arquivo `interact.js` e preencha o `CONFIG`:

javascript
const CONFIG = {
RPC_URL: "https://sepolia.infura.io/v3/SEU_INFURA_KEY",
PRIVATE_KEY: "SUA_PRIVATE_KEY",
FIDELITY_TOKEN: "0x719e6C427DA1DBFF7800DF3B2c1cD59b88e1fb13",
FIDELITY_NFT: "0x815AF36fbC0D24c5dFC86eCc3A3881255A89ACAB",
STAKING: "0x18fB769936fF3D9F65B47D4F003A537203849851",
GOVERNANCE: "0x24A00a58c0eBf54873F4D6594f1892b1e3B696E4",
};

### Executar o script

bash
node interact.js

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
├── interact.js # Script ethers.js de integração
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
- [ethers.js](https://docs.ethers.org/) `v6`
- [Remix IDE](https://remix.ethereum.org/)

---

## 👨‍💻 Autor

Desenvolvido como projeto final da disciplina **Web 3.0 — Residência em TIC 29**
Prof. Bruno Portes
