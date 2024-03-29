// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.6.2;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC165.sol";

/**
 * @title Standard ERC1155 token
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
contract ERC1155 is ERC165, IERC1155
{
    using SafeMath for uint256;
    using Address for address;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor() public {
        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);
    }

    /**
        @dev Get the specified address' balance for token with specified ID.

        Attempting to query the zero account for a balance will result in a revert.

        @param account The address of the token holder
        @param id ID of the token
        @return The account's balance of the token type requested
     */
    /// @notice postcondition _balances[id][account] == balance 
    function balanceOf(address account, uint256 id) public view  returns (uint256 balance) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
        @dev Get the balance of multiple account/token pairs.

        If any of the query accounts is the zero account, this query will revert.

        @param accounts The addresses of the token holders
        @param ids IDs of the tokens
        @return Balances for each account and token id pair
     */
    /// @notice postcondition batchBalances.length == accounts.length 
    /// @notice postcondition batchBalances.length == ids.length
    /// @notice postcondition forall (uint x) !( 0 <= x &&  x < batchBalances.length ) || batchBalances[x] == _balances[ids[x]][accounts[x]]  
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        
        returns (uint256[] memory batchBalances)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and IDs must have same lengths");

        batchBalances = new uint256[](accounts.length);
        
        /// @notice invariant (batchBalances.length == ids.length && batchBalances.length == accounts.length)
        /// @notice invariant (0 <= i && i <= accounts.length)
        /// @notice invariant (0 <= i && i <= ids.length)
        /// @notice invariant forall(uint k)  ids[k] == __verifier_old_uint(ids[k])
        /// @notice invariant forall (uint j) !(0 <= j && j < i && j < accounts.length ) || batchBalances[j] == _balances[ids[j]][accounts[j]]
        for (uint256 i = 0; i < accounts.length; ++i) {
            // require(accounts[i] != address(0), "ERC1155: some address in batch balance query is zero");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev Sets or unsets the approval of a given operator.
     *
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     *
     * Because an account already has operator privileges for itself, this function will revert
     * if the account attempts to set the approval status for itself.
     *
     * @param operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    /// @notice  postcondition _operatorApprovals[msg.sender][operator] ==  approved 
    /// @notice  emits  ApprovalForAll 
    function setApprovalForAll(address operator, bool approved) external   {
        require(msg.sender != operator, "ERC1155: cannot set approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
        @notice Queries the approval status of an operator for a given account.
        @param account   The account of the Tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    /// @notice postcondition _operatorApprovals[account][operator] == approved
    function isApprovedForAll(address account, address operator) public view  returns (bool approved) {
        return _operatorApprovals[account][operator];
    }

    /**
        @dev Transfers `value` amount of an `id` from the `from` address to the `to` address specified.
        Caller must be approved to manage the tokens being transferred out of the `from` account.
        If `to` is a smart contract, will call `onERC1155Received` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param id ID of the token type
        @param value Transfer amount
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    /// @notice postcondition to != address(0)
    /// @notice postcondition _operatorApprovals[from][msg.sender] || from == msg.sender
    /// @notice postcondition __verifier_old_uint ( _balances[id][from] ) >= value    
    /// @notice postcondition _balances[id][from] == __verifier_old_uint ( _balances[id][from] ) - value || from == to
    /// @notice postcondition _balances[id][to] == __verifier_old_uint ( _balances[id][to] ) + value || from == to
    /// @notice emits TransferSingle 
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
    {
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) == true,
            "ERC1155: need operator approval for 3rd party transfers"
        );

        _balances[id][from] = _balances[id][from].sub(value, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(value);

        emit TransferSingle(msg.sender, from, to, id, value);

        // _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, data);
    }

    /**
        @dev Transfers `values` amount(s) of `ids` from the `from` address to the
        `to` address specified. Caller must be approved to manage the tokens being
        transferred out of the `from` account. If `to` is a smart contract, will
        call `onERC1155BatchReceived` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param ids IDs of each token type
        @param values Transfer amounts per token type
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */

    /// @notice precondition forall (uint x) !(x >= 0 && x < values.length) || values[x] >= 0 
    /// @notice precondition !__verifier_eq(ids,values)
    /// @notice postcondition _operatorApprovals[from][msg.sender] || from == msg.sender
    /// @notice postcondition to != address(0)
    /// @notice postcondition ids.length == values.length
    /// @notice postcondition forall (uint x) !(x >= 0 && x < ids.length) || _balances[ids[x]][from] <= __verifier_old_uint (_balances[ids[x]][from] ) || from == to 
    /// @notice postcondition forall (uint x) !(x >= 0 && x < ids.length) || _balances[ids[x]][to] >= __verifier_old_uint (_balances[ids[x]][to] ) || from == to 
    /// @notice postcondition forall (uint x, address addr) (addr == from || addr == to || __verifier_old_uint(_balances[ids[x]][addr]) == _balances[ids[x]][addr])
    /// @notice emits TransferBatch 
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        public
    {
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) == true,
            "ERC1155: need operator approval for 3rd party transfers"
        );

        // / @notice invariant ids[i] == __verifier_old_uint(ids[i])
        // / @notice invariant values[i] == __verifier_old_uint(values[i])

        /// @notice invariant ids.length == values.length
        /// @notice invariant forall (uint x) !(x >= 0 && x < ids.length) || _balances[ids[x]][from] <= __verifier_old_uint (_balances[ids[x]][from] ) || from == to 
        /// @notice invariant forall (uint x) !(x >= 0 && x < ids.length) || _balances[ids[x]][to] >= __verifier_old_uint (_balances[ids[x]][to] ) || from == to 
        /// @notice invariant forall (uint x, address addr) (addr == from || addr == to || __verifier_old_uint(_balances[ids[x]][addr]) == _balances[ids[x]][addr])
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            
            _balances[id][from] = _balances[id][from] - value;
            _balances[id][to] =   _balances[id][to] + value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        // _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, values, data);
    }

    /**
     * @dev Internal function to mint an amount of a token with the given ID
     * @param to The address that will own the minted token
     * @param id ID of the token to be minted
     * @param value Amount of the token to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
     /// @notice emits TransferSingle  
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal  {
        require(to != address(0), "ERC1155: mint to the zero address");

        _balances[id][to] = _balances[id][to].add(value);
        emit TransferSingle(msg.sender, address(0), to, id, value);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, value, data);
    }

    /**
     * @dev Internal function to batch mint amounts of tokens with the given IDs
     * @param to The address that will own the minted token
     * @param ids IDs of the tokens to be minted
     * @param values Amounts of the tokens to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
     /// @notice emits TransferBatch  
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal  {
        require(to != address(0), "ERC1155: batch mint to the zero address");
        require(ids.length == values.length, "ERC1155: minted IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = values[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, values, data);
    }

    /**
     * @dev Internal function to burn an amount of a token with the given ID
     * @param account Account which owns the token to be burnt
     * @param id ID of the token to be burnt
     * @param value Amount of the token to be burnt
     */
     /// @notice emits TransferSingle  
    function _burn(address account, uint256 id, uint256 value) internal  {
        require(account != address(0), "ERC1155: attempting to burn tokens on zero account");

        _balances[id][account] = _balances[id][account].sub(
            value,
            "ERC1155: attempting to burn more than balance"
        );
        emit TransferSingle(msg.sender, account, address(0), id, value);
    }

    /**
     * @dev Internal function to batch burn an amounts of tokens with the given IDs
     * @param account Account which owns the token to be burnt
     * @param ids IDs of the tokens to be burnt
     * @param values Amounts of the tokens to be burnt
     */
     /// @notice emits TransferBatch
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory values) internal  {
        require(account != address(0), "ERC1155: attempting to burn batch of tokens on zero account");
        require(ids.length == values.length, "ERC1155: burnt IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                values[i],
                "ERC1155: attempting to burn more than balance for some token"
            );
        }

        emit TransferBatch(msg.sender, account, address(0), ids, values);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    )
        internal
        
    {
        if(to.isContract()) {
            require(
                IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) ==
                    IERC1155Receiver(to).onERC1155Received.selector,
                "ERC1155: got unknown value from onERC1155Received"
            );
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        internal
        
    {
        if(to.isContract()) {
            require(
                IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) ==
                    IERC1155Receiver(to).onERC1155BatchReceived.selector,
                "ERC1155: got unknown value from onERC1155BatchReceived"
            );
        }
    }
}
