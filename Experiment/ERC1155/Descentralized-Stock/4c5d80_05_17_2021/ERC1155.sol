// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma solidity ^0.6.0;

import './IERC1155.sol';
import './IERC1155TokenReceiver.sol';


contract Market is IERC1155, IERC1155TokenReceiver{
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    mapping (address => mapping(uint256 => uint256)) private _balance;
    mapping (address => uint256) private _etherBalance;
    mapping (address => mapping (address => bool)) private _approv;

    bytes4 private _ERC1155Received = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 private _ERC1155BatchReceived = bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));

    constructor() public {        
    }

    function onERC1155Received(
        address _operator, 
        address _from, 
        uint256 _id, 
        uint256 _value, 
        bytes calldata _data
    ) external  view returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address _operator, 
        address _from, 
        uint256[] calldata _ids, 
        uint256[] calldata _values, 
        bytes calldata _data
    ) external  view returns(bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    } 

    //test function
    function mint(uint256 id, uint256 amount) external { 
        _balance[msg.sender][id] = amount;
    }

    //test function
    function burn(uint256 id) external { 
        _balance[msg.sender][id] = 0;
    }


    //if ether are sended to the contract
    // fallback() external payable{
    //     require(msg.data.length == 0);
    //     _etherBalance[msg.sender] += msg.value;
    // }

    function depositEther() external payable{
        _etherBalance[msg.sender] += msg.value;
    }
    
    function etherBalanceOf(address owner) external view returns(uint256){
        return _etherBalance[owner];
    }

    /// @notice postcondition _to != address(0)
    /// @notice postcondition _approv[_from][msg.sender] || _from == msg.sender
    /// @notice postcondition __verifier_old_uint (_balance[_from][_id] ) >= _value
    /// @notice postcondition _balance[_from][_id] == __verifier_old_uint (_balance[_from][_id] ) - _value
    /// @notice postcondition _balance[_to][_id] == __verifier_old_uint (_balance[_to][_id] ) + _value
    /// @notice emits TransferSingle 
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(_to != address(0) && _from != address(0));
        require(_balance[_from][_id] >= _value);
        require(_approv[_from][msg.sender] || _from == msg.sender);
        _balance[_from][_id] = _balance[_from][_id] - _value;
        _balance[_to][_id] += _value; 
        emit TransferSingle(msg.sender, _from,  _to, _id, _value);
        require(_checkOnERC1155Received(msg.sender, _from, _to, _id, _value, _data));
    }

    /// @notice postcondition _to != address(0)
    /// @notice postcondition _approv[_from][msg.sender] || _from == msg.sender
    /// @notice emits TransferBatch
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) public {
        require(_to != address(0) && _from != address(0));
        require(_ids.length == _values.length);
        require(_approv[_from][msg.sender] || _from == msg.sender);

        
        for (uint256 i = 0; i < _ids.length; ++i) {
            require(_balance[_from][_ids[i]] >= _values[i]);
            _balance[_from][_ids[i]] -= _values[i];
            _balance[_to][_ids[i]] += _values[i];
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        require(_checkOnERC1155BatchReceived(msg.sender, _from, _to, _ids, _values, _data));
    }

    /// @notice postcondition _balance[_owner][_id] == balance
    function balanceOf(address _owner, uint256 _id) external  view returns (uint256 balance){
        require(_owner != address(0));
        return _balance[_owner][_id];
    }

    /// @notice postcondition _balances.length == _ids.length 
    /// @notice postcondition _balances.length == _owners.length
    /// @notice postcondition forall (uint x) !( 0 <= x &&  x < _balances.length ) || _balances[x] == _balance[_owners[x]][_ids[x]]
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public  view returns (uint256[] memory _balances){
        require(_owners.length == _ids.length);
        _balances = new uint256[](_owners.length);
        
        /// @notice invariant (_balances.length == _ids.length && _balances.length == _owners.length)
        /// @notice invariant (0 <= i && i <= _owners.length)
        /// @notice invariant (0 <= i && i <= _balances.length)
        /// @notice invariant forall(uint k)  _ids[k] == __verifier_old_uint(_ids[k])
        /// @notice invariant forall (uint j, uint z) !(0 <= j && j < i && j < _owners.length ) || _balances[j] == _balance[_owners[j]][_ids[j]]
        for (uint256 i = 0; i < _owners.length; ++i) {
            require(_owners[i] != address(0));
            _balances[i] = (_balance[_owners[i]][_ids[i]]); 
        }
        return _balances;
    }

    /// @notice  postcondition _approv[msg.sender][_operator] == _approved 
    /// @notice  emits ApprovalForAll
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0));
        require(msg.sender != _operator);

        _approv[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice postcondition _approv[_owner][_operator] == approved
    function isApprovedForAll(address _owner, address _operator) external  view returns (bool approved){
        return _approv[_owner][_operator];
    }

    function _checkOnERC1155Received(
        address _operator, 
        address _from, 
        address _to, 
        uint256 _tokenId, 
        uint256 _amount, 
        bytes memory _data
    ) internal view returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _amount,_data);
        return (retval == _ERC1155Received);
    }

    function _checkOnERC1155BatchReceived(
        address _operator, 
        address _from, 
        address _to, 
        uint256[] memory _Ids, 
        uint256[] memory _amounts, 
        bytes memory _data
    ) internal view returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _Ids, _amounts,_data);
        return (retval == _ERC1155BatchReceived);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        //assembly{ size := extcodesize(addr)}
        return size > 0;
    }
}