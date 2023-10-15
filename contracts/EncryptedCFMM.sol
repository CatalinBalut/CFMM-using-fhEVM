// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";

import "hardhat/console.sol";

import { EncryptedERC20 } from "./EncryptedERC20.sol";

contract EncryptedCFMM is EIP712WithModifier {
    EncryptedERC20 public immutable token0;
    EncryptedERC20 public immutable token1;

    euint32 internal reserve0;
    euint32 internal reserve1;

    euint32 private totalSupply;
    mapping(address => euint32) internal balances;

    // used for output authorization
    bytes32 private DOMAIN_SEPARATOR;

    // The owner of the contract.
    address public contractOwner;

    constructor(address _token0, address _token1) EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;

        token0 = EncryptedERC20(_token0);
        token1 = EncryptedERC20(_token1);
    }

    function _mint(address _to, euint32 _amount) private {
        balances[_to] = balances[_to] + _amount;
        totalSupply = totalSupply + _amount;
    }

    function _burn(address _from, euint32 _amount) private {
        balances[_from] = balances[_from] - _amount;
        totalSupply = totalSupply - _amount;
    }

    function _update(euint32 _reserve0, euint32 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(address _tokenIn, bytes calldata encryptedAmountIn) external returns (euint32 amountOut) {
        euint32 amount = TFHE.asEuint32(encryptedAmountIn);
        require(_tokenIn == address(token0) || _tokenIn == address(token1), "invalid token");
        // TFHE.req(TFHE.ge(amount, 0));
        bool isToken0 = _tokenIn == address(token0);
        (EncryptedERC20 tokenIn, EncryptedERC20 tokenOut, euint32 reserveIn, euint32 reserveOut) = isToken0
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), amount);

        euint32 amountInWithFee = TFHE.div(amount, 997);
        // amountOut = TFHE.div(
        //     TFHE.mul(reserveOut, amountInWithFee),
        //     TFHE.decrypt((TFHE.add(reserveIn, amountInWithFee)))
        // );

        // tokenOut.transfer(msg.sender, amountOut);

        // token0.balances(address(this));
        // _update(token0.balances(address(this)), token1.balances(address(this)));
    }

    function addLiquidity(bytes calldata _amount0, bytes calldata _amount1) public returns (euint32 shares) {
        console.log("AAAAAAAAAAAAA");
        euint32 amount0 = TFHE.asEuint32(_amount0);
        euint32 amount1 = TFHE.asEuint32(_amount1);

        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        // ebool isAboveR0 = TFHE.gt(reserve0, 0);
        // ebool isAboveR1 = TFHE.gt(reserve1, 0);

        // TFHE.eq(TFHE.mul(reserve0, amount1), TFHE.decrypt((reserve1 * amount0))); //must duble check

        // if (reserve0 > 0 || reserve1 > 0) {
        //     require(reserve0 * amount1 == reserve1 * amount0, "x / y != dx / dy");
        // }

        //returns (euint32 shares)
        //euint32 private totalSupply;
        //euint32 amount0 = TFHE.asEuint32(_amount0);
        shares = TFHE.cmux(
            TFHE.eq(totalSupply, 0),
            TFHE.asEuint32(_sqrt(amount0 * amount1)),
            TFHE.asEuint32(_sqrt(amount0 * amount1))
            // TFHE.div(TFHE.mul(amount0, totalSupply), 2)
        );

        // TFHE.min(TFHE.div(TFHE.mul(amount0, totalSupply), 2), TFHE.div(TFHE.mul(amount1, totalSupply), 2))

        // euint32 sd = TFHE.cmux(
        //     abc,
        //     TFHE.div(TFHE.mul(amount0, totalSupply), TFHE.decrypt(reserve0)),
        //     TFHE.div(TFHE.mul(amount1, totalSupply), TFHE.decrypt(reserve1))
        // );
        // shares = TFHE.cmux(
        //     abc,
        //     TFHE.div(TFHE.mul(amount0, totalSupply), TFHE.decrypt(reserve0)),
        //     TFHE.div(TFHE.mul(amount1, totalSupply), TFHE.decrypt(reserve1))
        // );

        // euint32 ab = TFHE.cmux(TFHE.eq(totalSupply, 0), TFHE.asEuint32(_sqrt(TFHE.mul(amount0, amount1))), sd);
        // THFE.div(TFHE.mul(amount0,totalSupply),reserve0)
        // THFE.div(TFHE.mul(amount0,totalSupply),reserve1)
        // TFHE.min(
        //     TFHE.div(TFHE.mul(amount0, totalSupply), reserve0),
        //     THFE.div(TFHE.mul(amount0, totalSupply), reserve1)
        // );
        // if (totalSupply == 0) {
        //     shares = TFHE.asEuint32(_sqrt(amount0 * amount1));
        // } else {
        //     shares = _min((amount0 * totalSupply) / reserve0, (amount1 * totalSupply) / reserve1);
        // }
        // require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);
        // _update(token0.balances(address(this)), token1.balances(address(this)));
    }

    // function removeLiquidity(bytes calldata _shares) external returns (euint32 amount0, euint32 amount1) {
    //     euint32 bal0 = token0.balances(address(this));
    //     euint32 bal1 = token1.balances(address(this));

    //     amount0 = (_shares * bal0) / totalSupply;
    //     amount1 = (_shares * bal1) / totalSupply;
    //     require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

    //     _burn(msg.sender, _shares);
    //     _update(bal0 - amount0, bal1 - amount1);

    //     token0.transfer(msg.sender, amount0);
    //     token1.transfer(msg.sender, amount1);
    // }

    function _sqrt(euint32 k) private view returns (uint32 z) {
        //euint32 z
        // TFHE.cmux(TFHE.gt(y, 3), val1, TFHE.cmux(TFHE.ne(y, 0)));
        // euint32 y = TFHE.asEuint32(y);
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
        // return TFHE.asEuint32(z);

        // if (TFHE.gt(y3)) {
        //     z = y;
        //     euint32 x = y / 2 + 1;
        //     while (x < z) {
        //         z = x;
        //         x = (y / x + x) / 2;
        //     }
        // } else if (y != 0) {
        //     z = 1;
        // }
    }

    // function _min(euint32 x, euint32 y) private pure returns (euint32) {
    //     return x <= y ? x : y;
    // }

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
