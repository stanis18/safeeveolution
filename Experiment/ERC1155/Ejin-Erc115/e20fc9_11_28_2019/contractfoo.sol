pragma solidity >=0.5.0;


contract contractfoo{

  uint success;
       
    /// @notice postcondition _to + _value == success  
    function foo(uint _to, uint _value)
        public {
        _foo(_to, _value);
    }

    function _foo(uint to, uint value) private {
        success = to + value;
    }

}