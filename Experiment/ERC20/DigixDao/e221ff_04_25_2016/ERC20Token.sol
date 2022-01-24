import "./Interfaces.sol";

contract Badge  {
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  address public owner;
  bool public locked;

  /// @return total amount of tokens
  uint256 public totalSupply;

  modifier ifOwner() {
    if (msg.sender != owner) {
      revert();
    } else {
      _;
    }
  }


  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Mint(address indexed _recipient, uint256 indexed _amount);
  event Approval(address indexed _owner, address indexed _spender, uint256  _value);

  constructor() public{
    owner = msg.sender;
  }

  function safeToAdd(uint a, uint b) public returns (bool) {
    return (a + b >= a);
  }

  function addSafely(uint a, uint b) public returns (uint result) {
    if (!safeToAdd(a, b)) {
      revert();
    } else {
      result = a + b;
      return result;
    }
  }

  function safeToSubtract(uint a, uint b) public returns (bool) {
    return (b <= a);
  }

  function subtractSafely(uint a, uint b) public returns (uint) {
    if (!safeToSubtract(a, b)) revert();
    return a - b;
  }

  function balanceOf(address _owner) public returns (uint256 balance) {
    return balances[_owner];
  }

  ///@notice emits Transfer
  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
      balances[_to] = addSafely(_value, balances[_to]);
      emit Transfer(msg.sender, _to, _value);
      success = true;
    } else {
      success = false;
    }
    return success;
  }

  ///@notice emits Transfer
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] = addSafely(balances[_to], _value);
      balances[_from] = subtractSafely(balances[_from], _value);
      allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value);
      emit Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  ///@notice emits Approval
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    success = true;
    return success;
  }

  function allowance(address _owner, address _spender) public returns (uint256 remaining) {
    remaining = allowed[_owner][_spender];
    return remaining;
  }

  ///@notice emits Mint
  function mint(address _owner, uint256 _amount) public ifOwner returns (bool success) {
    totalSupply += _amount;
    balances[_owner] += _amount;
    emit Mint(_owner, _amount);
    return true;
  }

  function setOwner(address _owner) public ifOwner returns (bool success) {
    owner = _owner;
    return true;
  }

}

/// @notice  invariant  totalSupply  ==  __verifier_sum_uint(balances)
contract Token {

  address public owner;
  address public config;
  bool public locked;
  address public dao;
  address public badgeLedger;
  uint256 public totalSupply;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) seller;

  /// @return total amount of tokens

  modifier ifSales() {
    if (!seller[msg.sender]) revert(); 
    _; 
  }

  modifier ifOwner() {
    if (msg.sender != owner) revert();
    _;
  }

  modifier ifDao() {
    if (msg.sender != dao) revert();
    _;
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Mint(address indexed _recipient, uint256  _amount);
  event Approval(address indexed _owner, address indexed _spender, uint256  _value);

 constructor (address _config) public{
    config = _config;
    owner = msg.sender;
    // address _initseller = ConfigInterface(_config).getConfigAddress("sale1:address");
    // seller[_initseller] = true; 
    badgeLedger = address(new Badge());
    locked = false;
  }

  function safeToAdd(uint a, uint b) public returns (bool) {
    return (a + b >= a);
  }

  function addSafely(uint a, uint b) public returns (uint result) {
    if (!safeToAdd(a, b)) {
      revert();
    } else {
      result = a + b;
      return result;
    }
  }

  function safeToSubtract(uint a, uint b) public returns (bool) {
    return (b <= a);
  }

  function subtractSafely(uint a, uint b) public returns (uint) {
    if (!safeToSubtract(a, b)) revert();
    return a - b;
  }
  /// @notice postcondition balances[_owner] == balance
  function balanceOf(address _owner) public returns (uint256 balance) {
    return balances[_owner];
  }

  /// @notice  postcondition ( ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender] ) - _value  && msg.sender  != _to ) ||   ( balances[msg.sender] ==  __verifier_old_uint ( balances[msg.sender]) && msg.sender  == _to ) &&  success ) || !success
  /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  && msg.sender  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) && msg.sender  == _to ) &&  success )   || !success
  /// @notice  emits Transfer 
  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
      balances[_to] = addSafely(balances[_to], _value);
      emit Transfer(msg.sender, _to, _value);
      success = true;
    } else {
      success = false;
    }
    return success;
  }

  /// @notice  postcondition ( ( balances[_from] ==  __verifier_old_uint (balances[_from] ) - _value  &&  _from  != _to ) ||   ( balances[_from] ==  __verifier_old_uint ( balances[_from] ) &&  _from== _to ) &&  success ) || !success
  /// @notice  postcondition ( ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) + _value  &&  _from  != _to ) ||   ( balances[_to] ==  __verifier_old_uint ( balances[_to] ) &&  _from  ==_to ) &&  success ) || !success
  /// @notice  postcondition  (allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) - _value && success) || (allowed[_from ][msg.sender] ==  __verifier_old_uint (allowed[_from ][msg.sender] ) && !success) ||  _from  == msg.sender
  /// @notice  postcondition  allowed[_from ][msg.sender]  <= __verifier_old_uint (allowed[_from ][msg.sender] ) ||  _from  == msg.sender
  /// @notice  emits Transfer 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] = addSafely(balances[_to], _value);
      balances[_from] = subtractSafely(balances[_from], _value);
      allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value);
      emit Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  /// @notice postcondition (allowed[msg.sender ][ _spender] ==  _value  &&  success) || ( allowed[msg.sender ][ _spender] ==  __verifier_old_uint ( allowed[msg.sender ][ _spender] ) && !success )    
  /// @notice emits Approval
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    success = true;
    return success;
  }

  /// @notice postcondition allowed[_owner][_spender] == remaining
  function allowance(address _owner, address _spender) public returns (uint256 remaining) {
    remaining = allowed[_owner][_spender];
    return remaining;
  }
  function mint(address _owner, uint256 _amount) public ifSales returns (bool success) {
    totalSupply = addSafely(_amount, totalSupply);
    balances[_owner] = addSafely(balances[_owner], _amount);
    return true;
  }

  // function mintBadge(address _owner, uint256 _amount)  public ifSales returns (bool success) {
  //   if (!Badge(badgeLedger).mint(_owner, _amount)) return false;
  //   return true;
  // }

  function registerDao(address _dao) public ifOwner returns (bool success) {
    if (locked == true) return false;
    dao = _dao;
    locked = true;
    return true;
  }

  function setDao(address _newdao)  public ifDao returns (bool success) {
    dao = _newdao;
    return true;
  }

  function isSeller(address _query) public returns (bool isseller) {
    return seller[_query];
  }

  function registerSeller(address _tokensales) public ifDao returns (bool success) {
    seller[_tokensales] = true;
    return true;
  }

  function unregisterSeller(address _tokensales) public ifDao returns (bool success) {
    seller[_tokensales] = false;
    return true;
  }

  function setOwner(address _newowner) public ifDao returns (bool success) {
    if(Badge(badgeLedger).setOwner(_newowner)) {
      owner = _newowner;
      success = true;
    } else {
      success = false;
    }
    return success;
  }

}
