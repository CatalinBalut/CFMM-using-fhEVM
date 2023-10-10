// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/abstracts/EIP712WithModifier.sol";

import "fhevm/lib/TFHE.sol";

contract EncryptedERC20 is EIP712WithModifier {
    euint32 private totalSupply;
    string public constant name = "Naraggara"; // City of Zama's battle
    string public constant symbol = "NARA";
    uint8 public constant decimals = 18;

    // used for output authorization
    bytes32 private DOMAIN_SEPARATOR;

    // A mapping from address to an encrypted balance.
    mapping(address => euint32) internal balances;

    // A mapping of the form mapping(owner => mapping(spender => allowance)).
    mapping(address => mapping(address => euint32)) internal allowances;

    // The owner of the contract.
    address public contractOwner;

    constructor() EIP712WithModifier("Authorization token", "1") {
        contractOwner = msg.sender;
    }

    // Sets the balance of the owner to the given encrypted balance.
    function mint(bytes calldata encryptedAmount) public onlyContractOwner {
        euint32 amount = TFHE.asEuint32(encryptedAmount);
        balances[contractOwner] = balances[contractOwner] + amount;
        totalSupply = totalSupply + amount;
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function transfer(address to, bytes calldata encryptedAmount) public {
        transfer(to, TFHE.asEuint32(encryptedAmount));
    }

    // Transfers an amount from the message sender address to the `to` address.
    function transfer(address to, euint32 amount) public {
        _transfer(msg.sender, to, amount);
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

    // Sets the `encryptedAmount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, bytes calldata encryptedAmount) public {
        address owner = msg.sender;
        _approve(owner, spender, TFHE.asEuint32(encryptedAmount));
    }

    // Returns the remaining number of tokens that `spender` is allowed to spend
    // on behalf of the caller. The returned ciphertext is under the caller public FHE key.
    function allowance(
        address spender,
        bytes32 publicKey,
        bytes calldata signature
    ) public view onlySignedPublicKey(publicKey, signature) returns (bytes memory) {
        address owner = msg.sender;

        return TFHE.reencrypt(_allowance(owner, spender), publicKey);
    }

    // Transfers `encryptedAmount` tokens using the caller's allowance.
    function transferFrom(address from, address to, bytes calldata encryptedAmount) public {
        transferFrom(from, to, TFHE.asEuint32(encryptedAmount));
    }

    // Transfers `amount` tokens using the caller's allowance.
    function transferFrom(address from, address to, euint32 amount) public {
        address spender = msg.sender;
        _updateAllowance(from, spender, amount);
        _transfer(from, to, amount);
    }

    function _approve(address owner, address spender, euint32 amount) internal {
        allowances[owner][spender] = amount;
    }

    function _allowance(address owner, address spender) internal view returns (euint32) {
        if (TFHE.isInitialized(allowances[owner][spender])) {
            return allowances[owner][spender];
        } else {
            return TFHE.asEuint32(0);
        }
    }

    function _updateAllowance(address owner, address spender, euint32 amount) internal {
        euint32 currentAllowance = _allowance(owner, spender);
        require(TFHE.decrypt(TFHE.le(amount, currentAllowance)));
        _approve(owner, spender, currentAllowance - amount);
    }

    // Transfers an encrypted amount.
    function _transfer(address from, address to, euint32 amount) internal {
        // Make sure the sender has enough tokens.
        require(TFHE.decrypt(TFHE.le(amount, balances[from])));

        // Add to the balance of `to` and subract from the balance of `from`.
        balances[to] = balances[to] + amount;
        balances[from] = balances[from] - amount;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }
}
