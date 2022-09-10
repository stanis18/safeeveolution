contract TokenInterface {

  struct User { bool locked; uint256 balance; uint256 badges; mapping (address => uint256) allowed; }

  mapping (address => User) users;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) seller;

  address config;
  address owner;
  uint256 public totalSupply;

  uint256 public totalBadges;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) seller;

   

  function badgesOf(address _owner) public returns (uint256 badge);
  function sendBadge(address _to, uint256 _value) public returns (bool success);

  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public returns (uint256 remaining);
  function mint(address _owner, uint256 _amount) public returns (bool success);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
