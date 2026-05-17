// ============================================================
// CONFIG
// ============================================================
const CONTRACTS = {
  TOKEN: "0x719e6C427DA1DBFF7800DF3B2c1cD59b88e1fb13",
  NFT: "0x815AF36fbC0D24c5dFC86eCc3A3881255A89ACAB",
  STAKING: "0x18fB769936fF3D9F65B47D4F003A537203849851",
  GOVERNANCE: "0x24A00a58c0eBf54873F4D6594f1892b1e3B696E4",
};

const ABI_TOKEN = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address, uint256) returns (bool)",
  "function burn(uint256) external",
];

const ABI_NFT = [
  "function possuiNFT(address) view returns (bool)",
  "function totalEmitidos() view returns (uint256)",
];

const ABI_STAKING = [
  "function stake(uint256) external",
  "function retirar(uint256) external",
  "function resgatarRecompensa() external",
  "function calcularRecompensa(address) view returns (uint256)",
  "function stakes(address) view returns (uint256, uint256, uint256)",
  "function calcularMultiplicador() view returns (uint256)",
  "function obterPrecoETH() view returns (int256)",
];

const ABI_GOVERNANCE = [
  "function criarProposta(string, uint8, uint256) external",
  "function votar(uint256, bool) external",
  "function executarProposta(uint256) external",
  "function consultarProposta(uint256) view returns (string, uint256, uint256, bool, bool)",
  "function totalPropostas() view returns (uint256)",
];

// ============================================================
// STATE
// ============================================================
let provider, signer, userAddress;
let token, nft, staking, governance;

// ============================================================
// TOAST
// ============================================================
function toast(msg, type = "info") {
  const t = document.getElementById("toast");
  t.textContent = msg;
  t.className = `show ${type}`;
  setTimeout(() => {
    t.className = "";
  }, 4000);
}

// ============================================================
// CONNECT
// ============================================================
async function connectWallet() {
  if (!window.ethereum) {
    toast("MetaMask não encontrada! Instale em metamask.io", "error");
    return;
  }

  try {
    toast("Conectando à MetaMask...", "info");
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);

    const network = await provider.getNetwork();
    if (network.chainId !== 11155111n) {
      toast("Troque para a rede Sepolia na MetaMask!", "error");
      return;
    }

    signer = await provider.getSigner();
    userAddress = await signer.getAddress();

    token = new ethers.Contract(CONTRACTS.TOKEN, ABI_TOKEN, signer);
    nft = new ethers.Contract(CONTRACTS.NFT, ABI_NFT, signer);
    staking = new ethers.Contract(CONTRACTS.STAKING, ABI_STAKING, signer);
    governance = new ethers.Contract(
      CONTRACTS.GOVERNANCE,
      ABI_GOVERNANCE,
      signer,
    );

    document.getElementById("btn-connect").style.display = "none";
    document.getElementById("wallet-info").style.display = "flex";
    document.getElementById("wallet-address").textContent =
      userAddress.slice(0, 6) + "..." + userAddress.slice(-4);

    toast("Carteira conectada!", "success");
    await loadData();
  } catch (e) {
    toast("Erro ao conectar: " + e.message, "error");
  }
}

// ============================================================
// LOAD DATA
// ============================================================
async function loadData() {
  if (!userAddress) return;

  try {
    // Token saldo
    const saldo = await token.balanceOf(userAddress);
    const saldoFmt = parseFloat(ethers.formatUnits(saldo, 18)).toFixed(2);
    document.getElementById("token-saldo").textContent = saldoFmt + " FDL";
    document.getElementById("stat-saldo").textContent = saldoFmt;

    // NFT
    const possui = await nft.possuiNFT(userAddress);
    const totalNFT = await nft.totalEmitidos();
    document.getElementById("nft-status").textContent = possui
      ? "✅ Possui NFT"
      : "❌ Não possui";
    document.getElementById("nft-status").style.color = possui
      ? "var(--accent3)"
      : "var(--muted)";
    document.getElementById("nft-total").textContent = totalNFT.toString();

    const badge = document.getElementById("nft-badge");
    if (possui) {
      badge.className = "nft-badge owned";
      badge.innerHTML =
        '<div class="nft-emoji">🏆</div><div class="nft-text owned">Membro Fidelidade — NFT #' +
        totalNFT +
        "</div>";
    }

    // Staking
    const stakeInfo = await staking.stakes(userAddress);
    const stakeAmt = parseFloat(ethers.formatUnits(stakeInfo[0], 18)).toFixed(
      2,
    );
    document.getElementById("stake-amount").textContent = stakeAmt + " FDL";
    document.getElementById("stat-stake").textContent = stakeAmt;

    const reward = await staking.calcularRecompensa(userAddress);
    const rewardFmt = parseFloat(ethers.formatUnits(reward, 18)).toFixed(4);
    document.getElementById("stake-reward").textContent = rewardFmt + " FDL";
    document.getElementById("stat-recompensa").textContent = rewardFmt;

    // Multiplicador
    const multi = await staking.calcularMultiplicador();
    const multiVal = Number(multi);
    document.getElementById("stake-multi").textContent =
      multiVal === 2 ? "2x 🔥" : multiVal === 15 ? "1.5x ⚡" : "1x";

    // ETH Price via Chainlink
    const preco = await staking.obterPrecoETH();
    const precoUSD = (Number(preco) / 1e8).toFixed(2);
    document.getElementById("eth-price").textContent = "$" + precoUSD;
    document.getElementById("stat-eth").textContent = "$" + precoUSD;

    // DAO
    const totalProps = await governance.totalPropostas();
    document.getElementById("dao-total").textContent = totalProps.toString();
  } catch (e) {
    console.error("Erro ao carregar dados:", e);
  }
}

// ============================================================
// TOKEN — BURN
// ============================================================
async function burnTokens() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const amt = document.getElementById("burn-amount").value;
  if (!amt || amt <= 0) {
    toast("Informe uma quantidade válida.", "error");
    return;
  }

  try {
    toast("Aguardando confirmação...", "info");
    const tx = await token.burn(ethers.parseUnits(amt, 18));
    await tx.wait();
    toast("Tokens queimados com sucesso!", "success");
    await loadData();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

// ============================================================
// STAKING
// ============================================================
async function fazerStake() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const amt = document.getElementById("stake-input").value;
  if (!amt || amt <= 0) {
    toast("Informe uma quantidade válida.", "error");
    return;
  }

  try {
    const parsed = ethers.parseUnits(amt, 18);
    toast("Aprovando tokens...", "info");
    const txApprove = await token.approve(CONTRACTS.STAKING, parsed);
    await txApprove.wait();

    toast("Fazendo stake...", "info");
    const txStake = await staking.stake(parsed);
    await txStake.wait();
    toast("Stake realizado com sucesso! 🎉", "success");
    await loadData();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

async function retirarStake() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const amt = document.getElementById("stake-input").value;
  if (!amt || amt <= 0) {
    toast("Informe uma quantidade válida.", "error");
    return;
  }

  try {
    toast("Retirando tokens...", "info");
    const tx = await staking.retirar(ethers.parseUnits(amt, 18));
    await tx.wait();
    toast("Tokens retirados com sucesso!", "success");
    await loadData();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

async function resgatarRecompensa() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  try {
    toast("Resgatando recompensas...", "info");
    const tx = await staking.resgatarRecompensa();
    await tx.wait();
    toast("Recompensa resgatada! Verifique se ganhou um NFT 🏆", "success");
    await loadData();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

// ============================================================
// GOVERNANCE
// ============================================================
async function criarProposta() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const valor = document.getElementById("dao-valor").value;
  const desc = document.getElementById("dao-desc").value;
  if (!valor || !desc) {
    toast("Preencha valor e descrição.", "error");
    return;
  }

  try {
    toast("Criando proposta...", "info");
    const tx = await governance.criarProposta(
      desc,
      0,
      ethers.parseUnits(valor, 18),
    );
    await tx.wait();
    toast("Proposta criada com sucesso!", "success");
    await loadData();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

async function consultarProposta() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const id = document.getElementById("dao-id").value;
  if (!id) {
    toast("Informe o ID da proposta.", "error");
    return;
  }

  try {
    const [desc, favor, contra, encerrada, executada] =
      await governance.consultarProposta(id);

    const totalVotos = Number(ethers.formatUnits(favor + contra, 18));
    const pctFavor =
      totalVotos > 0
        ? ((Number(ethers.formatUnits(favor, 18)) / totalVotos) * 100).toFixed(
            0,
          )
        : 0;

    document.getElementById("proposta-info").innerHTML = `
      <div class="proposta-item">
        <div class="proposta-header">
          <div class="proposta-desc">${desc}</div>
          <div class="proposta-id">#${id}</div>
        </div>
        <div class="vote-bar">
          <div class="vote-fill" style="width: ${pctFavor}%"></div>
        </div>
        <div class="proposta-votes">
          <span>✅ ${parseFloat(ethers.formatUnits(favor, 18)).toFixed(0)} FDL</span>
          <span>${encerrada ? (executada ? "⚡ Executada" : "🔒 Encerrada") : "🗳️ Em votação"}</span>
          <span>❌ ${parseFloat(ethers.formatUnits(contra, 18)).toFixed(0)} FDL</span>
        </div>
      </div>`;
  } catch (e) {
    toast("Erro ao consultar: " + (e.reason || e.message), "error");
  }
}

async function votar(favoravel) {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const id = document.getElementById("dao-id").value;
  if (!id) {
    toast("Informe o ID da proposta.", "error");
    return;
  }

  try {
    toast("Registrando voto...", "info");
    const tx = await governance.votar(id, favoravel);
    await tx.wait();
    toast(
      "Voto registrado! " + (favoravel ? "✅ A favor" : "❌ Contra"),
      "success",
    );
    await consultarProposta();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

async function executarProposta() {
  if (!signer) {
    toast("Conecte sua carteira primeiro!", "error");
    return;
  }
  const id = document.getElementById("dao-id").value;
  if (!id) {
    toast("Informe o ID da proposta.", "error");
    return;
  }

  try {
    toast("Executando proposta...", "info");
    const tx = await governance.executarProposta(id);
    await tx.wait();
    toast("Proposta executada!", "success");
    await consultarProposta();
  } catch (e) {
    toast("Erro: " + (e.reason || e.message), "error");
  }
}

// Auto-refresh a cada 30s
setInterval(() => {
  if (userAddress) loadData();
}, 30000);
