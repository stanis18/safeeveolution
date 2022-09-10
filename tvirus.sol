pragma solidity >= 0.5.0;

contract ExampleContract {

    function _msgSender() internal view  returns (address) {
        return msg.sender;
    }

    mapping (uint256 => mapping(address => uint256)) private _balances;
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    mapping (address => mapping(address => bool)) private _operatorApprovals;


    /// @notice postcondition ids.length == accounts.length 
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids ) public view returns (uint256[] memory batchBalances) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        batchBalances = new uint256[](accounts.length);

        /// @notice invariant (batchBalances.length == ids.length && batchBalances.length == accounts.length)
        for (uint256 i = 0; i < ids.length; ++i) {
            // batchBalances[i] = _balances[ids[i]][accounts[i]];
        }
        return batchBalances;
    }

      // / @notice postcondition forall(uint x) !(0 <= x && x < amounts.length) || amounts[x] == 8 || 0 < x || x > amounts.length
      // / @notice postcondition forall(uint x) !(0 <= x &&  x < ids.length) || _balances[ids[x]][from] ==  amounts[x]
      
       
      // / @notice postcondition forall (uint x) !(x >= 0 && x < amounts.length) || _balances[ids[x]][to] == amounts[x] || from == to

      // / @notice invariant ( i >= 0 && i <= amounts.length )
        // / @notice invariant ( i >= 0 && i <= ids.length )
        // / @notice invariant forall (uint j) !(0 <= j && j < i && j < amounts.length ) || _balances[ids[j]][to] == amounts[j] || from == to


      /// @notice postcondition ids.length == amounts.length
      /// @notice postcondition forall (uint x) !(x >= 0 && x < amounts.length) || _balances[ids[x]][from] == amounts[x] 
      function testFunction(address from, uint256[] memory ids, uint256[] memory amounts) public {
        require(ids.length == amounts.length);
        /// @notice invariant ids.length == amounts.length
        /// @notice invariant forall (uint k) ids[k] == __verifier_old_uint(ids[k])
        /// @notice invariant forall (uint m) amounts[m] == __verifier_old_uint(amounts[m])
        /// @notice invariant forall (uint j) !(0 <= j && j < i && j < ids.length ) || _balances[ids[j]][from] == amounts[j] 
        for (uint256 i = 0; i < amounts.length; ++i) {
            _balances[ids[i]][from] = amounts[i];
        }
     }





     
    //  // / @notice modifies _balances if xvirus >=  5
    //  /// @notice postcondition ids.length == amounts.length
    //  /// @notice postcondition forall (uint j) !(0 <= j && j < amounts.length ) || amounts[j] >=  5 
    //  function X_X(address from,  uint256[] memory ids, uint256[] memory amounts, uint256 xvirus) public {

    //        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        
          
          
    //        // / @notice invariant ( 0 <= i && i <= amounts.length ) || xvirus >=  5
    //       // / @notice invariant ( 0 <= i && i <= ids.length ) || xvirus >=  5 
    //       // / @notice invariant (amounts.length == ids.length )

    //        // / @notice invariant forall(uint k)  ids[k] == __verifier_old_uint(ids[k]) 
          
    //       // / @notice invariant forall(uint k)  !( 0 <= k && k < i  && k < ids.length )    || ids[k] == __verifier_old_uint(ids[k])

    //       // / @notice invariant i <= amounts.length 
    //       // / @notice invariant i <= ids.length 

    //       /// @notice invariant ids.length == amounts.length
    //       /// @notice invariant forall (uint z) !( 0 <= z && z < i  && z < amounts.length ) || amounts[z] >=  5  
    //       for (uint256 i = 0; i < amounts.length; ++i) {

    //         //  _balances[ids[i]][from] = amounts[i];
    //         require(amounts[i] >=  5, "ERC1155: insufficient balance for transfer");
    //         // _balances[ids[i]][from] = amounts[i];
    //       }
    //  }



    

    
    


    // / @notice exists (uint f) 0 <= f && f < amounts.length && (_balances[id[f]][from] < amounts[f])
//     /// @notice postcondition _operatorApprovals[from][msg.sender] || from == msg.sender
//     /// @notice postcondition to != address(0)
//     /// @notice emits TransferBatch  
//     function safeBatchTransferFrom(address from,address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) public {
//         require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
//         require(to != address(0), "ERC1155: transfer to the zero address");
//         require( from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved" );

//         address operator = _msgSender();

//         _beforeTokenTransfer(operator, from, to, ids, amounts, data);

//         /// @notice invariant (0 <= i && i <= amounts.length) 
//         /// @notice invariant (0 <= i && i <= ids.length)
//         /// @notice invariant  (amounts.length == ids.length) 
//         /// @notice invariant forall (uint e) !(0 <= e && e < ids.length) || (_balances[ids[e]][from] >= amounts[e])
//         for (uint256 i = 0; i < ids.length; ++i) {
//             uint256 id = ids[i];
//             uint256 amount = amounts[i];

//             require(_balances[id][from] >= amount, "ERC1155: insufficient balance for transfer");
//           //   _balances[id][from] = 6;
//           //   _balances[id][to] = 5;
//         }

//         emit TransferBatch(operator, from, to, ids, amounts);

//         _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
//     }


    // /// @notice postcondition _operatorApprovals[account][operator] == approved 
    // function isApprovedForAll(address account, address operator) public view   returns (bool approved) {
    //     return _operatorApprovals[account][operator];
    // }


    //  function _beforeTokenTransfer( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) internal  { }


    //   function _doSafeBatchTransferAcceptanceCheck(
    //     address operator,
    //     address from,
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // )
    //     private
    // {
      
    // }

}