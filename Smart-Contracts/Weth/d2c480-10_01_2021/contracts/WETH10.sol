// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2020
pragma solidity >= 0.5.0;

import "./interfaces/IWETH10.sol";
import "./interfaces/IERC3156FlashBorrower.sol";

interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external;
}

interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external;
}


/// @dev WETH10 is an Ether ERC20 wrapper. You can `deposit` Ether and obtain Wrapped Ether which can then be operated as an ERC20 token. You can
/// `withdraw` Ether from WETH10, which will burn Wrapped Ether in your wallet. The amount of Wrapped Ether in any wallet is always identical to the
/// balance of Ether deposited minus the Ether withdrawn with that specific wallet.
contract WETH10 is IWETH10 {

    string public constant name = "Wrapped Ether v10";
    string public constant symbol = "WETH10";
    uint8  public constant decimals = 18;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @dev Records amount of WETH10 token owned by account.
    mapping (address => uint256) public  balanceOf;

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping (address => uint256) public  nonces;

    /// @dev Records number of WETH10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public  allowance;

    /// @dev Current amount of flash minted WETH.
    uint256 public  flashMinted;

    /// @dev Fallback, `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    receive() external payable {
        _mintTo(msg.sender, msg.value);
    }

    /// @dev Returns the total supply of WETH10 as the Ether held in this contract.
    function totalSupply() external view  returns(uint256) {
        return address(this).balance + flashMinted;
    }

    /// @dev `msg.value` of ether sent to contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to caller account.
    function deposit() external  payable {
        _mintTo(msg.sender, msg.value);
    }

    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from zero address to `to` account.
    function depositTo(address to) external  payable {
        _mintTo(to, msg.value);
    }


    /// @dev `msg.value` of ether sent to contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token and transfer to account (`to`) cannot cause overflow.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external  payable returns (bool success) {
        _mintTo(to, msg.value);
        ITransferReceiver(to).onTokenTransfer(msg.sender, msg.value, data);
        return true; // TODO: Return the output of previous line
    }

    /// @dev Return the amount of WETH10 that can be flash lended.
    function maxFlashAmount(address token) external view  returns (uint256) {
        return token == address(this) ? type(uint112).max - address(this).balance - flashMinted : 0; // Can't underflow - L108
    }

    /// @dev Return the fee (zero) for flash lending an amount of WETH10.
    function flashFee(address token, uint256) external view  returns (uint256) {
        require(token == address(this), "WETH: flash mint only WETH10");
        return 0;
    }

    /// @dev Flash lends `value` WETH10 tokens to the receiver address.
    /// By the end of the transaction, `value` WETH10 tokens will be burned from the receiver.
    /// The flash minted WETH10 is not backed by real Ether, but can be withdrawn as such up to the Ether balance of this contract.
    /// Arbitrary data can be passed as a bytes calldata parameter.
    /// Emits two {Transfer} events for minting and burning of the flash minted amount.
    function flashLoan(address receiver, address token, uint256 value, bytes calldata data) external  {
        require(token == address(this), "WETH: flash mint only WETH10");
        flashMinted += value;
        _mintTo(receiver, value);

        IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, address(this), value, 0, data);

        _decreaseAllowance(receiver, address(this), value);
        _burnFrom(receiver, value);
        flashMinted -= value;
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external  {
        _burnFrom(msg.sender, value);
        _transferEther(msg.sender, value);
    }

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ether to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` WETH10 token to zero address from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external  {
        _burnFrom(msg.sender, value);
        _transferEther(to, value);
    }

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ether to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to zero address from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external  {
        if (from != msg.sender) _decreaseAllowance(from, msg.sender, value);
        _burnFrom(from, value);
        _transferEther(to, value);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    function approve(address spender, uint256 value) external  returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed on `spender` with the `data` parameter.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Approval} event.
    /// For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external  returns (bool) {
        _approve(msg.sender, spender, value);
        IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
        return true; // TODO: Return the output of previous line
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's WETH10 token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// WETH10 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external  {
        require(block.timestamp <= deadline, "WETH: Expired permit");

        uint256 chainId;
        assembly {chainId := chainid()}
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "WETH: invalid permit");
        _approve(owner, spender, value);
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`).
    /// A transfer to `address(0)` triggers a withdraw of the sent tokens.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    function transfer(address to, uint256 value) external  returns (bool) {
        return _transferFrom(msg.sender, to, value);
    }

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers a withdraw of the sent tokens in favor of caller.
    /// Returns boolean value indicating whether operation succeeded.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function transferFrom(address from, address to, uint256 value) external  returns (bool) {
        if (from != msg.sender) _decreaseAllowance(from, msg.sender, value);
        return _transferFrom(from, to, value);
    }

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), after which a call is executed to an ERC677-compliant contract.
    /// Returns boolean value indicating whether operation succeeded.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external  returns (bool) {
        _transferFrom(msg.sender, to, value);
        ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
        return true; // TODO: Return the output of previous line
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's WETH10 token.
    /// Emits {Approval} event.
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @dev Decreases the allowance of `spender` account over `owner` account's by `value` WETH10 token.
    /// If the allowance of `spender` account over `owner` account's is type(uin112).max WETH10 token this function does nothing.
    /// Emits {Approval} event.
    /// Requirements:
    /// - allowance of `spender` account over `owner must be at least `value` WETH10 token.
    function _decreaseAllowance(address owner, address spender, uint256 value) internal {
        uint256 allowed = allowance[owner][spender];
        if (allowed != type(uint256).max) {
            require(allowed >= value, "WETH: request exceeds allowance");
            _approve(owner, spender, allowed - value);
        }
    }

    /// @dev Moves `value` WETH10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers a withdraw of the sent tokens in favor of caller.
    /// Returns boolean value indicating whether operation succeeded.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function _transferFrom(address from, address to, uint256 value) internal returns (bool) {
        if(to != address(0)) { // Transfer
            uint256 balance = balanceOf[from];
            require(balance >= value, "WETH: transfer amount exceeds balance");

            balanceOf[from] = balance - value;
            balanceOf[to] += value;
            emit Transfer(from, to, value);
        } else { // Withdraw
            _burnFrom(from, value);
            _transferEther(payable(to), value);
        }
        
        return true;
    }

    /// @dev Transfers `value` Ether to account (`to`).
    function _transferEther(address payable to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "WETH: Ether transfer failed");
    }

    /// @dev Creates `value` WETH10 token on account (`to`).
    /// Requirements:
    /// - The resulting WETH10 supply must remain below type(uint112).max.
    ///
    /// Emits {Transfer} event.
    function _mintTo(address to, uint256 value) internal {
        require(address(this).balance + flashMinted <= type(uint112).max, "WETH: supply limit exceeded");
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    /// @dev Destroys `value` WETH10 token from account (`from`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    ///
    /// Emits {Transfer} and {Approval} events.
    /// Requirements:
    /// - owner account (`from`) must have at least `value` WETH10 token.
    /// - caller account must have at least `value` allowance from account (`from`).
    function _burnFrom(address from, uint256 value) internal {
        uint256 balance = balanceOf[from];
        require(balance >= value, "WETH: burn amount exceeds balance");
        balanceOf[from] = balance - value;
        emit Transfer(from, address(0), value);
    }
}

