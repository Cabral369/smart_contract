// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interface do FidelityToken — evita importar o contrato inteiro
interface IFidelityToken {
    function mint(address destinatario, uint256 quantidade) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// Interface do FidelityNFT
interface IFidelityNFT {
    function concederNFT(address destinatario) external;
    function possuiNFT(address usuario) external view returns (bool);
}

// Interface simplificada do Chainlink Price Feed
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/**
 * Staking
 * Contrato central do protocolo. Usuários travam FDL tokens e
 * acumulam recompensas ajustadas pelo preço do ETH via Chainlink.
 *
 * ReentrancyGuard: proteção contra ataques de reentrancy.
 * Reentrancy é quando um contrato malicioso chama a função de saque
 * repetidamente antes do saldo ser atualizado, drenando os fundos.
 */
contract Staking is ReentrancyGuard, Ownable {

    // Referências aos outros contratos do protocolo
    IFidelityToken public fidelityToken;
    IFidelityNFT public fidelityNFT;
    AggregatorV3Interface public priceFeed;

    // Recompensa base por segundo de staking (em tokens FDL)
    uint256 public recompensaBase = 1 * 10 ** 18;

    // Limite de tokens para ganhar NFT
    uint256 public constant LIMITE_NFT = 500 * 10 ** 18;

    // Struct com dados do stake de cada usuário
    struct StakeInfo {
        uint256 quantidade;
        uint256 timestamp;
        uint256 recompensaAcumulada;
    }

    mapping(address => StakeInfo) public stakes;

    // Eventos
    event TokensStakados(address indexed usuario, uint256 quantidade);
    event TokensRetirados(address indexed usuario, uint256 quantidade);
    event RecompensaResgatada(address indexed usuario, uint256 recompensa);

    /**
     * Construtor: recebe os endereços dos contratos já deployados.
     *
     * Endereço Chainlink ETH/USD na Sepolia:
     * 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor(
        address _fidelityToken ,
        address _fidelityNFT,
        address _priceFeed
    ) Ownable(msg.sender) {
        fidelityToken = IFidelityToken(_fidelityToken);
        fidelityNFT = IFidelityNFT(_fidelityNFT);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * Retorna o preço atual do ETH em USD via Chainlink.
     * O valor retornado tem 8 casas decimais (ex: 200000000000 = $2000.00)
     */
    function obterPrecoETH() public view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Calcula o multiplicador de recompensa baseado no preço do ETH.
     * ETH > $3000 → multiplicador 2x
     * ETH > $2000 → multiplicador 1.5x
     * Caso contrário → multiplicador 1x
     */
    function calcularMultiplicador() public view returns (uint256) {
        int256 preco = obterPrecoETH();
        if (preco > 3000 * 10 ** 8) return 2;
        if (preco > 2000 * 10 ** 8) return 15; // representa 1.5x (dividido por 10 no cálculo)
        return 10; // representa 1x (dividido por 10 no cálculo)
    }

    /**
     * Calcula a recompensa pendente de um usuário.
     * Recompensa = tempo em stake × recompensa base × multiplicador
     */
    function calcularRecompensa(address usuario) public view returns (uint256) {
        StakeInfo memory info = stakes[usuario];
        if (info.quantidade == 0) return info.recompensaAcumulada;

        uint256 tempo = block.timestamp - info.timestamp;
        uint256 multiplicador = calcularMultiplicador();
        uint256 recompensa = (tempo * recompensaBase * multiplicador) / 10;

        return info.recompensaAcumulada + recompensa;
    }

    /**
     * Usuário faz stake de tokens FDL.
     * nonReentrant: impede chamadas reentrantes maliciosas.
     *
     * quantidade Quantidade de tokens a travar
     */
    function stake(uint256 quantidade) external nonReentrant {
        require(quantidade > 0, "Quantidade deve ser maior que zero.");

        // Salva recompensa acumulada antes de atualizar o stake
        stakes[msg.sender].recompensaAcumulada = calcularRecompensa(msg.sender);
        stakes[msg.sender].quantidade += quantidade;
        stakes[msg.sender].timestamp = block.timestamp;

        // Transfere tokens do usuário para o contrato
        fidelityToken.transferFrom(msg.sender, address(this), quantidade);

        emit TokensStakados(msg.sender, quantidade);
    }

    /**
     * Usuário retira tokens do stake.
     * quantidade Quantidade de tokens a retirar
     */
    function retirar(uint256 quantidade) external nonReentrant {
        require(stakes[msg.sender].quantidade >= quantidade, "Saldo insuficiente em stake.");

        // Salva recompensa acumulada antes de atualizar o stake
        stakes[msg.sender].recompensaAcumulada = calcularRecompensa(msg.sender);
        stakes[msg.sender].quantidade -= quantidade;
        stakes[msg.sender].timestamp = block.timestamp;

        fidelityToken.transfer(msg.sender, quantidade);

        emit TokensRetirados(msg.sender, quantidade);
    }

    /**
     * Usuário resgata as recompensas acumuladas em FDL.
     * Se atingir o limite, recebe também um NFT de fidelidade.
     */
    function resgatarRecompensa() external nonReentrant {
        uint256 recompensa = calcularRecompensa(msg.sender);
        require(recompensa > 0, "Nenhuma recompensa disponivel.");

        // Zera recompensa acumulada e atualiza timestamp
        stakes[msg.sender].recompensaAcumulada = 0;
        stakes[msg.sender].timestamp = block.timestamp;

        // Minta tokens de recompensa para o usuário
        fidelityToken.mint(msg.sender, recompensa);

        // Concede NFT se atingiu o limite e ainda não possui
        if (recompensa >= LIMITE_NFT && !fidelityNFT.possuiNFT(msg.sender)) {
            fidelityNFT.concederNFT(msg.sender);
        }

        emit RecompensaResgatada(msg.sender, recompensa);
    }

    /**
     * Permite ao owner ajustar a recompensa base.
     * Será controlado pela DAO via votação.
     */
    function ajustarRecompensaBase(uint256 novaRecompensa) external onlyOwner {
        recompensaBase = novaRecompensa;
    }
}