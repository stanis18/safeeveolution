// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165
{
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant public ERC1155_RECEIVED       = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);


/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
        @notice Transfers value amount of an _id from the _from address to the _to addresses specified. Each parameter array should be the same length, with each index correlating.
        @dev MUST emit TransferSingle event on success.
        Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
        MUST Throw if `_to` is the zero address.
        MUST Throw if `_id` is not a valid token ID.
        MUST Throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    Source addresses
        @param _to      Target addresses
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    /// @notice postcondition _to != address(0)
    /// @notice postcondition operatorApproval[_from][msg.sender] || _from == msg.sender
    /// @notice postcondition __verifier_old_uint ( balances[_id][_from] ) >= _value
    /// @notice postcondition balances[_id][_from] == __verifier_old_uint ( balances[_id][_from] ) - _value
    /// @notice postcondition balances[_id][_to] == __verifier_old_uint ( balances[_id][_to] ) + _value
    /// @notice emits TransferSingle 
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == ERC1155_RECEIVED);
        }
    }

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
        @dev MUST emit TransferBatch event on success.
        Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
        MUST Throw if `_to` is the zero address.
        MUST Throw if any of the `_ids` is not a valid token ID.
        MUST Throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    /// @notice postcondition _to != address(0)
    /// @notice postcondition operatorApproval[_from][msg.sender] || _from == msg.sender
    /// @notice emits TransferBatch 
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) public {

        // MUST Throw on errors
        require(_to != address(0), "_to must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated,
        // call onERC1155BatchReceived if the destination is a contract
        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_BATCH_RECEIVED);
        }
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    /// @notice postcondition balances[_id][_owner] == balance  
    function balanceOf(address _owner, uint256 _id) external view returns (uint256 balance) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }


    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested
     */
    /// @notice postcondition balances_.length == _ids.length 
    /// @notice postcondition balances_.length == _owners.length
    /// @notice postcondition forall (uint x) !( 0 <= x &&  x < balances_.length ) || balances_[x] == balances[_ids[x]][_owners[x]] 
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public view returns (uint256[] memory balances_) {

        require(_owners.length == _ids.length);

        balances_ = new uint256[](_owners.length);

        /// @notice invariant (balances_.length == _ids.length && balances_.length == _owners.length)
        /// @notice invariant (0 <= i && i <= _owners.length)
        /// @notice invariant (0 <= i && i <= balances_.length)
        /// @notice invariant forall(uint k)  _ids[k] == __verifier_old_uint(_ids[k])
        /// @notice invariant forall (uint j, uint z) !(0 <= j && j < i && j < _owners.length ) || balances_[j] == balances[_ids[j]][_owners[j]]
        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    /// @notice  postcondition operatorApproval[msg.sender][_operator] == _approved 
    /// @notice  emits  ApprovalForAll
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    /// @notice postcondition operatorApproval[_owner][_operator] == approved
    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved) {
        return operatorApproval[_owner][_operator];
    }
}
