// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.6.0;

import './IERC1155.sol';
import './ERC1155Receiver.sol';

contract Market is ERC1155, ERC1155TokenReceiver{

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    mapping(address => mapping(address => bool)) private _isApproved;
    mapping(address => mapping(uint256 => uint256)) private _balance;
    bytes4 private _ERC1155Received;

    constructor() public{

    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }    

    /// @notice postcondition _to != address(0)
    /// @notice postcondition _isApproved[_from][msg.sender] || _from == msg.sender
    /// @notice postcondition __verifier_old_uint ( _balance[_from][_id] ) >= _value
    /// @notice postcondition _balance[_from][_id] == __verifier_old_uint ( _balance[_from][_id] ) - _value
    /// @notice postcondition _balance[_to][_id] == __verifier_old_uint ( _balance[_to][_id] ) + _value
    /// @notice emits TransferSingle 
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
        require(_to != address(0));
        require(this.balanceOf(_from, _id) >= _value);
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender));
        require(_checkOnERC1155Received(msg.sender, _from, _to, _id, _value, _data) == true);

        _balance[_from][_id] = this.balanceOf(_from, _id) - _value;
        _balance[_to][_id] += _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value); 
    }

    /// @notice postcondition _to != address(0)
    /// @notice postcondition _isApproved[_from][msg.sender] || _from == msg.sender
    /// @notice emits TransferBatch
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) public{
        require(_to != address(0));
        require(_ids.length == _values.length);
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender));
        require(_checkOnERC1155BatchReceived(msg.sender, _from, _to, _ids, _values, _data) == true);

        for (uint256 i = 0; i < _ids.length; ++i){
            uint256 id = _ids[i];
            uint256 amount = _values[i];

            require(this.balanceOf(_from,id) >= amount);
            _balance[_from][id] = this.balanceOf(_from,id) - amount;
            _balance[_to][id] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
    }

    /// @notice postcondition _balance[_owner][_id] == balance
    function balanceOf(address _owner, uint256 _id) external view returns (uint256 balance){
        return _balance[_owner][_id];
    }

    /// @notice postcondition batch.length == _ids.length 
    /// @notice postcondition batch.length == _owners.length
    /// @notice postcondition forall (uint x) !( 0 <= x &&  x < batch.length ) || batch[x] == _balance[_owners[x]][_ids[x]]
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public view returns (uint256[] memory batch){
        require(_owners.length == _ids.length);

        batch = new uint256[](_owners.length);

        /// @notice invariant (batch.length == _ids.length && batch.length == _owners.length)
        /// @notice invariant (0 <= i && i <= _owners.length)
        /// @notice invariant (0 <= i && i <= batch.length)
        /// @notice invariant forall(uint k)  _ids[k] == __verifier_old_uint(_ids[k])
        /// @notice invariant forall (uint j, uint z) !(0 <= j && j < i && j < _owners.length ) || batch[j] == _balance[_owners[j]][_ids[j]]
        for (uint256 i = 0; i < _owners.length; ++i){
            batch[i] = this.balanceOf(_owners[i], _ids[i]);
        }

        return batch;
    }

    /// @notice  postcondition _isApproved[msg.sender][_operator] == _approved 
    /// @notice  emits  ApprovalForAll
    function setApprovalForAll(address _operator, bool _approved) external{
        require(msg.sender != _operator);

        _isApproved[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice postcondition _isApproved[_owner][_operator] == approved
    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved){
        return _isApproved[_owner][_operator];
    }

    function _checkOnERC1155Received(address _operator, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) internal returns (bool){
        if (!isContract(_to)) {
            return true;
        }
         _ERC1155Received = this.onERC1155Received(_operator, _from, _tokenId, _amount, _data);
        bytes4 retval = ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _amount,_data);
        return (retval == _ERC1155Received);
    }

    function _checkOnERC1155BatchReceived(address _operator, address _from, address _to, uint256[] memory _Ids, uint256[] memory _amounts, bytes memory _data) internal returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        _ERC1155Received = this.onERC1155BatchReceived(_operator, _from, _Ids, _amounts, _data);
        bytes4 retval = ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _Ids, _amounts,_data);
        return (retval == _ERC1155Received);
    }

     function isContract(address _a) internal returns (bool){
        uint len;
        // assembly { len := extcodesize(_a) }
        return len != 0;
    }

}