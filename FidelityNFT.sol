// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * FidelityNFT
 * NFT ERC-721 concedido como distintivo de membro no protocolo de fidelidade.
 *
 * ERC-721: padrão para tokens não fungíveis (NFT) — cada token é único
 * e possui um ID próprio. Ideal para representar conquistas ou memberships.
 *
 * Diferença do ERC-20:
 * - ERC-20: todos os tokens são iguais (fungíveis), como dinheiro
 * - ERC-721: cada token é único (não fungível), como um certificado
 */
contract FidelityNFT is ERC721, Ownable {

    // Contador para gerar IDs únicos para cada NFT
    uint256 private _tokenIdCounter;

    // Controla quais endereços já receberam o NFT (apenas 1 por usuário)
    mapping(address => bool) public possuiNFT;

    // Limite mínimo de tokens FDL para receber o NFT
    uint256 public constant LIMITE_MINIMO = 500 * 10 ** 18;

    // Eventos
    event NFTConcedido(address indexed destinatario, uint256 tokenId);

    /**
     * Construtor: define nome e símbolo da coleção NFT.
     */
    constructor() ERC721("FidelityBadge", "FDB") Ownable(msg.sender) {}

    /**
     * Concede um NFT de fidelidade ao usuário.
     * Apenas o owner (contrato de Staking) pode chamar esta função.
     * Cada endereço só pode receber um NFT.
     *
     * destinatario Endereço que receberá o NFT
     */
    function concederNFT(address destinatario) external onlyOwner {
        require(!possuiNFT[destinatario], "Usuario ja possui o NFT de fidelidade.");

        // Incrementa o contador e usa como ID do novo token
        _tokenIdCounter++;
        uint256 novoTokenId = _tokenIdCounter;

        possuiNFT[destinatario] = true;

        // Faz o mint do NFT para o destinatário
        _safeMint(destinatario, novoTokenId);

        emit NFTConcedido(destinatario, novoTokenId);
    }

    /**
     * Retorna o total de NFTs emitidos até o momento.
     */
    function totalEmitidos() external view returns (uint256) {
        return _tokenIdCounter;
    }
}