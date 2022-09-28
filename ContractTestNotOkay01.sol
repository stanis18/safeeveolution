contract ContractTestNotOkay01 {

      mapping (uint256 => uint256) private _balances;

      // Veja abaixo no invariante que falha a explicação.
      // Essa condição abaixo faz com que o mapeamento mencionado seja funcional.
      // /// @notice precondition forall (uint x, uint y) (x == y) || ids[x] != ids[y] 
      /// @notice postcondition ids.length == amounts.length
      /// @notice postcondition forall (uint x) !(x >= 0 && x < amounts.length) || _balances[ids[x]] == amounts[x] 
      function testFunction(address frm, uint256[] memory ids, uint256[] memory amounts) public {
        require(amounts.length == ids.length);
        
        /// @notice invariant ids.length == amounts.length
        /// @notice invariant ids[i] == __verifier_old_uint(ids[i])
        /// @notice invariant amounts[i] == __verifier_old_uint(amounts[i])
        // Esse invariante abaixo só funciona se o mapeamento ids[i] -> amounts[i] for
        // funcional. Isto é um valor de ids[i] só mapea para um valor de amounts[i].
        // Se tiver por exemplo ids[0] = 1, ids[1] = 1, amounts[0] = 0 e amounts[1] = 1, n ote
        // que temos 2 mapeamentos com 1 (1 -> 0 e 1 -> 1) isso quer dizer que quando i == 2
        // esse invariante não se mantem porque _balances[ids[0]] == _balances[ids[1]] == amounts[1] == 1,
        // mas a condição exige que _balances[ids[0]] == amounts[0] == 0.
        /// @notice invariant forall (uint j) !(0 <= j && j < i && j < ids.length) || _balances[ids[j]] == amounts[j] 
        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]] = amounts[i];
        }
     }
}