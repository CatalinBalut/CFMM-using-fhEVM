// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";
import "fhevm/lib/TFHE.sol";

import { EncryptedERC20 } from "./EncryptedERC20.sol";

contract EncryptedCFMM is EIP712WithModifier {
    EncryptedERC20 public immutable tokenA;
    EncryptedERC20 public immutable tokenB;

    euint32 internal reserveA;
    euint32 internal reserveB;

    euint32 private totalSupply;
    mapping(address => euint32) internal balances;

    // used for output authorization
    bytes32 private DOMAIN_SEPARATOR;

    // The owner of the contract.
    address public contractOwner;

    constructor(address _tokenA, address _tokenB) EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;

        tokenA = EncryptedERC20(_tokenA);
        tokenB = EncryptedERC20(_tokenB);
    }

    function _mint(address _to, euint32 _amount) private {
        balances[_to] = balances[_to] + _amount;
        totalSupply = totalSupply + _amount;
    }

    function _burn(address _from, euint32 _amount) private {
        balances[_from] = balances[_from] - _amount;
        totalSupply = totalSupply - _amount;
    }

    function _update(euint32 _reserveA, euint32 _reserveB) private {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function swap(address _tokenIn, bytes calldata encryptedAmountIn) external returns (euint32 amountOut) {
        euint32 amountIn = TFHE.asEuint32(encryptedAmountIn);
        require(_tokenIn == address(tokenA) || _tokenIn == address(tokenB), "invalid token");
        // TFHE.req(TFHE.ge(amount, 0));
        bool istokenA = _tokenIn == address(tokenA);
        (EncryptedERC20 tokenIn, EncryptedERC20 tokenOut, euint32 reserveIn, euint32 reserveOut) = istokenA
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        // euint32 amountInWithFee = TFHE.div(amountIn * TFHE.asEuint32(97), 100);
        // amountOut = TFHE.div(TFHE.mul(reserveOut, amountIn), TFHE.decrypt((TFHE.add(reserveIn, amountIn))));
        amountOut = TFHE.asEuint32(TFHE.decrypt(reserveOut * amountIn) / TFHE.decrypt((TFHE.add(reserveIn, amountIn))));

        tokenOut.transfer(msg.sender, amountOut);
        _update(tokenA.balances(address(this)), tokenB.balances(address(this)));
    }

    function addLiquidity(bytes calldata _amountA, bytes calldata _amountB) public returns (euint32 shares) {
        euint32 amountA = TFHE.asEuint32(_amountA);
        euint32 amountB = TFHE.asEuint32(_amountB);

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        //Probably can be written without decrypt
        if (TFHE.decrypt(TFHE.gt(reserveA, 0)) || TFHE.decrypt(TFHE.gt(reserveB, 0))) {
            require(TFHE.decrypt(TFHE.eq(TFHE.mul(reserveA, amountB), TFHE.decrypt((reserveB * amountA)))));
        }

        if (TFHE.decrypt(TFHE.eq(totalSupply, 0))) {
            shares = TFHE.asEuint32(_sqrt(amountA * amountB));
        } else {
            shares = TFHE.min(
                TFHE.div(TFHE.mul(amountA, totalSupply), TFHE.decrypt(reserveA)),
                TFHE.div(TFHE.mul(amountB, totalSupply), TFHE.decrypt(reserveB))
            );
        }

        TFHE.optReq(TFHE.gt(shares, 0));
        _mint(msg.sender, shares);
        _update(tokenA.balances(address(this)), tokenB.balances(address(this)));
    }

    function removeLiquidity(bytes calldata _shares) external returns (euint32 amountA, euint32 amountB) {
        euint32 bal0 = tokenA.balances(address(this));
        euint32 bal1 = tokenB.balances(address(this));
        euint32 shares = TFHE.asEuint32(_shares);

        // uint32 _totalSupply = TFHE.decrypt(totalSupply);
        // amountA = TFHE.div(TFHE.mul(shares, bal0), _totalSupply);
        // amountB = TFHE.div(TFHE.mul(shares, bal1), _totalSupply);
        amountA = TFHE.asEuint32(TFHE.decrypt(TFHE.mul(shares, bal0)) / TFHE.decrypt(totalSupply));
        amountB = TFHE.asEuint32(TFHE.decrypt(TFHE.mul(shares, bal1)) / TFHE.decrypt(totalSupply));
        // TFHE.optReq(TFHE.gt(amountA, 0));
        // TFHE.optReq(TFHE.gt(amountB, 0));
        _burn(msg.sender, shares);
        _update(bal0 - amountA, bal1 - amountB);

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function _sqrt(euint32 k) private view returns (uint32 z) {
        uint32 y = TFHE.decrypt(k);
        if (y > 3) {
            z = y;
            uint32 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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
        EncryptedERC20 tokenReserve
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        if (tokenReserve == tokenA) return TFHE.reencrypt(reserveA, publicKey, 0);
        if (tokenReserve == tokenB) return TFHE.reencrypt(reserveB, publicKey, 0);
    }

    // Returns the balance of the caller encrypted under the provided public key.
    function balanceOf(
        bytes32 publicKey,
        bytes calldata signature
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        return TFHE.reencrypt(balances[msg.sender], publicKey, 0);
    }
}
