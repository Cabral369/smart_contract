// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interface do Staking para executar decisões aprovadas pela DAO
interface IStaking {
    function ajustarRecompensaBase(uint256 novaRecompensa) external;
}

// Interface do FidelityToken para verificar saldo do votante
interface IFidelityToken {
    function balanceOf(address account) external view returns (uint256);
}

/**
 * Governance
 * DAO simplificada para votação de parâmetros do protocolo.
 *
 * Fluxo de governança:
 * 1. Owner cria uma proposta (ex: alterar recompensa base)
 * 2. Holders de FDL votam a favor ou contra
 * 3. Após o prazo, qualquer um pode executar se aprovada
 *
 * Poder de voto: proporcional ao saldo de FDL do votante.
 * Quórum mínimo: 100 tokens FDL em votos favoráveis para aprovar.
 */
contract Governance is Ownable {

    IStaking public staking;
    IFidelityToken public fidelityToken;

    // Quórum mínimo de votos para aprovar uma proposta
    uint256 public constant QUORUM_MINIMO = 100 * 10 ** 18;

    // Duração de cada votação em segundos (1 dia)
    uint256 public constant DURACAO_VOTACAO = 1 days;

    // Tipos de proposta suportados pela DAO
    enum TipoProposta { AlterarRecompensaBase }

    // Struct representando uma proposta de governança
    struct Proposta {
        uint256 id;
        string descricao;
        TipoProposta tipo;
        uint256 valorProposto;
        uint256 votosFavor;
        uint256 votosContra;
        uint256 prazo;
        bool executada;
    }

    // Contador de propostas
    uint256 public totalPropostas;

    // Mapping de propostas
    mapping(uint256 => Proposta) public propostas;

    // Controla se um endereço já votou em uma proposta
    mapping(uint256 => mapping(address => bool)) public jaVotou;

    // Eventos
    event PropostaCriada(uint256 indexed id, string descricao, uint256 prazo);
    event VotoRegistrado(uint256 indexed propostaId, address indexed votante, bool favoravel, uint256 peso);
    event PropostaExecutada(uint256 indexed id, bool aprovada);

    /**
     * Construtor: recebe endereços do Staking e do FidelityToken.
     */
    constructor(
        address _staking,
        address _fidelityToken
    ) Ownable(msg.sender) {
        staking = IStaking(_staking);
        fidelityToken = IFidelityToken(_fidelityToken);
    }

    /**
     * Owner cria uma nova proposta de governança.
     *
     * descricao Descrição legível da proposta
     * tipo Tipo da proposta (ex: AlterarRecompensaBase)
     * valorProposto Novo valor a ser aplicado se aprovada
     */
    function criarProposta(
        string calldata descricao,
        TipoProposta tipo,
        uint256 valorProposto
    ) external onlyOwner {
        totalPropostas++;

        propostas[totalPropostas] = Proposta({
            id: totalPropostas,
            descricao: descricao,
            tipo: tipo,
            valorProposto: valorProposto,
            votosFavor: 0,
            votosContra: 0,
            prazo: block.timestamp + DURACAO_VOTACAO,
            executada: false
        });

        emit PropostaCriada(totalPropostas, descricao, block.timestamp + DURACAO_VOTACAO);
    }

    /**
     * Holder de FDL vota em uma proposta ativa.
     * Peso do voto = saldo de FDL do votante.
     * Cada endereço só pode votar uma vez por proposta.
     *
     * propostaId ID da proposta
     * favoravel true = a favor, false = contra
     */
    function votar(uint256 propostaId, bool favoravel) external {
        Proposta storage proposta = propostas[propostaId];

        require(block.timestamp < proposta.prazo, "Votacao encerrada.");
        require(!jaVotou[propostaId][msg.sender], "Voce ja votou nesta proposta.");

        uint256 peso = fidelityToken.balanceOf(msg.sender);
        require(peso > 0, "Voce precisa ter tokens FDL para votar.");

        jaVotou[propostaId][msg.sender] = true;

        if (favoravel) {
            proposta.votosFavor += peso;
        } else {
            proposta.votosContra += peso;
        }

        emit VotoRegistrado(propostaId, msg.sender, favoravel, peso);
    }

    /**
     * Executa uma proposta aprovada após o prazo de votação.
     * Qualquer pessoa pode chamar esta função após o prazo.
     * A proposta é aprovada se votosFavor >= QUORUM_MINIMO
     * e votosFavor > votosContra.
     *
     * propostaId ID da proposta a executar
     */
    function executarProposta(uint256 propostaId) external {
        Proposta storage proposta = propostas[propostaId];

        require(block.timestamp >= proposta.prazo, "Votacao ainda em andamento.");
        require(!proposta.executada, "Proposta ja foi executada.");

        proposta.executada = true;

        bool aprovada = proposta.votosFavor >= QUORUM_MINIMO &&
                        proposta.votosFavor > proposta.votosContra;

        if (aprovada) {
            if (proposta.tipo == TipoProposta.AlterarRecompensaBase) {
                staking.ajustarRecompensaBase(proposta.valorProposto);
            }
        }

        emit PropostaExecutada(propostaId, aprovada);
    }

    /**
     * Retorna o status atual de uma proposta.
     */
    function consultarProposta(uint256 propostaId) external view returns (
        string memory descricao,
        uint256 votosFavor,
        uint256 votosContra,
        bool encerrada,
        bool executada
    ) {
        Proposta memory p = propostas[propostaId];
        return (
            p.descricao,
            p.votosFavor,
            p.votosContra,
            block.timestamp >= p.prazo,
            p.executada
        );
    }
}