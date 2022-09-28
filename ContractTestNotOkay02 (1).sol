contract ContractTestNotOkay02 {

    // Aliasing
    // Funciona se incluir a precondição abaixo.
    // sem ela pode ser que ids[0] e amounts[0] apontem para a mesma
    // posição de memória.
    // /// @notice precondition !__verifier_eq(ids,amounts)
    /// @notice postcondition ids[0] == 5
    /// @notice postcondition amounts[0] == 6
    function testFunction(uint256[] memory ids, uint256[] memory amounts) public {
        // Aliasing
        ids[0] = 5;
        amounts[0] = 6;
    }
}