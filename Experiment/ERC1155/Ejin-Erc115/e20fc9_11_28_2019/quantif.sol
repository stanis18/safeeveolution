pragma solidity >=0.5.0;

import "./SafeMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
//pragma solidity ^0.4.24;

import "./SafeMath.sol";
// import "./Address.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";


contract ERC1155 is IERC1155, ERC165
{
    using SafeMath for uint256;
    // using Address for address;

    bytes4 constant public ERC1155_RECEIVED = 0xf23a6e61;
    mapping (address => mapping(address => bool)) internal operatorApproval;
    
    
    /// @notice postcondition _ids.length == _values.length
    /// @notice postcondition _to != address(0)
    /// @notice postcondition operatorApproval[_from][msg.sender] == true || _from == msg.sender
    /// @notice postcondition forall (uint t) !( 0 <= t &&  t < _ids.length ) || (balances[_ids[t]][_from] <= __verifier_old_uint(balances[_ids[t]][_from]) || _from == _to )
    /// @notice postcondition forall (uint t) !( 0 <= t &&  t < _ids.length ) || (balances[_ids[t]][_to] >= __verifier_old_uint(balances[_ids[t]][_to]) || _from == _to )
    /// @notice emits TransferBatch
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) public {
        require(_to != address(0));
        require(_ids.length == _values.length);

        uint256 id;
        uint256 value;
        uint256 i;

        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");
        
        /// @notice invariant (0 <= i && i <= _ids.length)
        /// @notice invariant (0 <= i && i <= _values.length)
        /// @notice invariant forall(uint k)  _ids[k] == __verifier_old_uint(_ids[k])
        /// @notice invariant forall(uint k)  _values[k] == __verifier_old_uint(_values[k])
        /// @notice invariant _ids.length == _values.length
        for (i = 0; i < _ids.length; ++i) {
            id = _ids[i];
            value = _values[i];
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // if (_to.isContract()) {
        //     require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_RECEIVED);
        // }
    }

    mapping (uint256 => mapping(address => uint256)) internal balances;

    /// @notice postcondition balances_.length == _ids.length 
    /// @notice postcondition balances_.length == _owners.length
    /// @notice postcondition forall (uint t) !( 0 <= t &&  t < balances_.length ) || balances_[t] == balances[_ids[t]][_owners[t]]
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public  returns (uint256[] memory balances_) {

        require(_owners.length == _ids.length);
        balances_ = new uint256[](_owners.length);

         // / @notice invariant forall (uint j) !(0 <= j && j < i && j < _owners.length) || balances_[j] == balances[_ids[j]][_owners[j]]
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






    
}


// contract SortedSequence {
//     uint[] items;

//     /// @notice precondition forall (uint i, uint j) !(0 <= i && i < j && j < items.length) || (items[i] < items[j])
//     /// @notice postcondition forall (uint i, uint j) !(0 <= i && i < j && j < items.length) || (items[i] < items[j])
//     function add(uint x) public {
//         require(items.length == 0 || x > items[items.length-1], "");
//         items.push(x);
//     }

//     // function pop() public {
//     //     require(items.length > 0, "Empty array");
//     //     items.pop();
//     // }
// }

// contract ExistTest {
//     uint256[] arr;

//     /// @notice postcondition property(arr) (u) (arr[u] == tvirus)
//     function test(uint256 tvirus) public  {
//         /// @notice invariant forall (uint j) !(0 <= j && j < i) ||  arr[i] ==  tvirus || arr[i] !=  tvirus
//         for (uint i = 0; i < arr.length; i += 1) {
//             arr[i] =  tvirus;
//         }
//     }
// }

// contract SortedSequence {
//     uint[] items;

//     using SafeMath for uint256;

//     mapping (uint256 => mapping(address => uint256)) internal balances;
//     mapping (address => mapping(address => bool)) internal operatorApproval;

//     /// @notice modifies balances
//     function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {
//         require(_to != address(0));
//         require(_ids.length == _values.length);

//         uint256 id;
//         uint256 value;
//         uint256 i;

//         require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

//         for (i = 0; i < _ids.length; ++i) {
//             id = _ids[i];
//             value = _values[i];

//             balances[id][_from] = balances[id][_from] -value;
//             balances[id][_to] = value + balances[id][_to];
//         }
//     }

//     /// @notice postcondition accounts.length == ids.length
//     /// @notice postcondition accounts.length == batchBalances.length
//     function balanceOfBatch(address[] memory accounts,uint256[] memory ids)
//         public view returns (uint256[] memory batchBalances){
//         require(accounts.length == ids.length, "ERC1155: accounts and IDs must have same lengths");

//         //batchBalances = new uint256[](accounts.length);
//         batchBalances = new uint256[](accounts.length);
        
//         // / @notice invariant forall (uint z) !(0 <= z && z < batchBalances.length && z < i && batchBalances.length == accounts.length) || (batchBalances[z] == 1)

         
//          // / @notice invariant forall (uint z) !(0 <= z && z < i && batchBalances.length == accounts.length && accounts.length == ids.length) || (batchBalances[z] == 1)
          
//         //  )
//         //  /// @notice invariant forall (uint z) !(0 <= z && z < i && batchBalances.length == accounts.length && z < batchBalances.length ) || ( batchBalances[z] == 1 && accounts[z] != address(0) || accounts[z] == address(0)) 
         
//          // / @notice invariant (accounts.length == batchBalances.length)
//          // / @notice invariant forall (uint j) !(0 <= j && j < i) || accounts[j] != address(0)
         
//          /// @notice invariant (accounts.length == batchBalances.length && accounts.length == ids.length)
//          /// @notice invariant (0 <= i && i <= accounts.length)
//          /// @notice invariant forall (uint j) !(0 <= j && j < i && j < batchBalances.length) || batchBalances[j] == 1
//          for (uint256 i = 0; i < accounts.length; ++i) {
             
//         //     //  accounts[i] == address(0);


//         //     // require(accounts[i] != address(0), "ERC1155: some address in batch balance query is zero");

//             batchBalances[i] = 1;

//         //     // batchBalances[i] = balances[ids[i]][accounts[i]];
//         }

//         // /// @notice postcondition property(arr) (u) (arr[u] == tvirus)
//         // function test(uint256 tvirus) public  {
//         //     /// @notice invariant forall (uint j) !(0 <= j && j < i) ||  arr[i] ==  tvirus || arr[i] !=  tvirus
//         //     for (uint i = 0; i < arr.length; i += 1) {
//         //         arr[i] =  tvirus;
//         //     }
//         // }
  

//         return batchBalances;
//     }

//  }

// // contract ExistTest {
// //     bool[] arr;

// //     /// @notice postcondition property(arr) (u) (arr[u] == true )
// //     /// @notice modifies arr
// //     // / @notice postcondition exists (uint u) (0 <= u && u < arr.length && arr[u]) || !result
// //     function test() public returns (bool result) {
// //         bool res = false;
// //         /// @notice invariant (0 <= i && i <= arr.length)
// //         /// @notice invariant forall (uint j) !(0 <= j && j < i) || j < arr.length
// //         // / @notice invariant exists (uint j) (0 <= j && j < i && arr[j] >= __verifier_old_uint (arr[j]))
// //         for (uint i = 0; i < arr.length; i += 1) {
            
// //             // uint256 c;
// //             // c = arr[i] + 1;
// //             // require(c >= arr[i]);
            
// //              arr[i] = true;
// //         }
// //         return true;
// //     }
// // }