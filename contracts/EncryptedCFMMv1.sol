// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";

import "hardhat/console.sol";

import { EncryptedERC20 } from "./EncryptedERC20.sol";

//A primive version of CFMM
contract EncryptedCFMMv1 is EIP712WithModifier {
    EncryptedERC20 public immutable tokenA;
    EncryptedERC20 public immutable tokenB;
    euint32 internal reserveA;
    euint32 internal reserveB;

    // used for output authorization
    bytes32 private DOMAIN_SEPARATOR;

    // The owner of the contract.
    address public contractOwner;

    euint32 internal totalSupply;
    mapping(address => euint32) internal balances;

    constructor(address _token0, address _token1) EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;

        tokenA = EncryptedERC20(_token0);
        tokenB = EncryptedERC20(_token1);
    }

    function addLiquidity(bytes calldata amountA, bytes calldata amountB) external {
        euint32 amount0 = TFHE.asEuint32(amountA);
        euint32 amount1 = TFHE.asEuint32(amountB);
        tokenA.transferFrom(msg.sender, address(this), amount0);
        tokenB.transferFrom(msg.sender, address(this), amount1);

        balances[msg.sender] = balances[msg.sender] + amount0 * amount1;

        reserveA = TFHE.add(reserveA, amount0);
        reserveB = TFHE.add(reserveB, amount1);

        totalSupply = TFHE.add(totalSupply, reserveA * reserveB);
    }

    function swap(EncryptedERC20 token, bytes calldata amountIn) public {
        euint32 amount = TFHE.asEuint32(amountIn);
        // reserveA = TFHE.asEuint32(1);
        // reserveB = TFHE.asEuint32(2);

        if (token == tokenA) {
            token.transferFrom(msg.sender, address(this), amount);
            euint32 oldReserveB = reserveB;
            reserveA = reserveA + amount;
            reserveB = TFHE.div(totalSupply, TFHE.decrypt(reserveB));
            // reserveB = TFHE.asEuint32(TFHE.decrypt(totalSupply) / TFHE.decrypt(reserveA));
            tokenA.transfer(msg.sender, oldReserveB - reserveB);
        } else if (token == tokenB) {
            token.transferFrom(msg.sender, address(this), amount);
            euint32 oldReserveA = reserveA; //50000
            reserveB = reserveB + amount; //57000
            reserveA = TFHE.div(totalSupply, TFHE.decrypt(reserveB));
            // reserveA = reserveA - TFHE.asEuint32(TFHE.decrypt(totalSupply) / TFHE.decrypt(reserveB)); //43859
            tokenB.transfer(msg.sender, oldReserveA - reserveA);
        }
    }

    function getTotalSupply(
        bytes32 publicKey,
        bytes calldata signature
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(totalSupply, publicKey, 0);
    }

    function getReserve(
        bytes32 publicKey,
        bytes calldata signature,
        EncryptedERC20 token
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        // if (token == tokenB) return TFHE.reencrypt(reserveB, publicKey, 0);
        return TFHE.reencrypt(reserveA, publicKey, 0);
    }

    // Returns the balance of the caller encrypted under the provided public key.
    function balanceOf(
        bytes32 publicKey,
        bytes calldata signature
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(balances[msg.sender], publicKey, 0);
    }
}
