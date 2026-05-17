// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin fornece implementações seguras e auditadas dos padrões ERC.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * FidelityToken
 * Token ERC-20 usado como recompensa no protocolo de fidelidade.
 *
 * ERC-20: padrão para tokens fungíveis — todos os tokens são iguais,
 * assim como pontos de fidelidade ou moeda corrente.
 *
 * Ownable: garante que apenas o dono do contrato possa mintar novos tokens,
 * evitando emissão não autorizada.
 */
contract FidelityToken is ERC20, Ownable {

    /**
     * Construtor: define nome, símbolo e faz mint inicial para o owner.
     * O owner será o contrato de Staking (definido após o deploy).
     */
    constructor() ERC20("FidelityToken", "FDL") Ownable(msg.sender) {
        // Mint inicial de 1.000.000 tokens para o deployer
        // 10 ** decimals() = 1 token com 18 casas decimais (padrão ERC-20)
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /**
     * Permite ao owner mintar novos tokens.
     * Será chamado pelo contrato de Staking para distribuir recompensas.
     *
     * destinatario Endereço que receberá os tokens
     * quantidade Quantidade de tokens a mintar
     */
    function mint(address destinatario, uint256 quantidade) external onlyOwner {
        _mint(destinatario, quantidade);
    }

    /**
     * Permite ao usuário queimar (destruir) seus próprios tokens.
     * Útil para resgatar recompensas fora da blockchain.
     *
     * quantidade Quantidade de tokens a queimar
     */
    function burn(uint256 quantidade) external {
        _burn(msg.sender, quantidade);
    }
}