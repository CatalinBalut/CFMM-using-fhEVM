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

        if (token == tokenA) {
            token.transferFrom(msg.sender, address(this), amount);
            euint32 oldReserveA = reserveA;
            reserveA = reserveA + amount;
            reserveB = TFHE.div(totalSupply, TFHE.decrypt(reserveB));
            tokenA.transfer(msg.sender, reserveB - oldReserveA);
        } else if (token == tokenB) {
            token.transferFrom(msg.sender, address(this), amount);
            euint32 oldReserveB = reserveB;
            reserveB = reserveB + amount;
            reserveA = TFHE.div(totalSupply, TFHE.decrypt(reserveB));
            tokenB.transfer(msg.sender, reserveB - oldReserveB);
        }
    }

    euint32 result;

    function setDiv(bytes calldata _amount) public {
        euint32 amount = TFHE.asEuint32(_amount);

        euint32 div = TFHE.div(amount, 2);

        result = div;
    }

    function getTotalSupply(
        bytes32 publicKey,
        bytes calldata signature
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(totalSupply, publicKey, 0);
    }

    // Returns the balance of the caller encrypted under the provided public key.
    function balanceOf(
        bytes32 publicKey,
        bytes calldata signature
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(balances[msg.sender], publicKey, 0);
    }
}
