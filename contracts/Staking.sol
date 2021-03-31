pragma solidity ^0.7.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Math {
    
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

}

interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
}

interface IStaking{
    function stake(address token, uint256 amount) external returns (bool);
    function unclaimed(address user, address token) external view returns(uint256){
}

contract Staking is ReentrancyGuard, IStaking {

  address private rainiTokenContract;
  address private rainiLPContract;
  address public admin;

  struct Info {
     uint256 timestamp;
     uint8 staked;
     uint256 tokens;
  }

  constructor(address _rainiToken, address _rainiLPToken){
      rainiTokenContract = _rainiToken;
      rainiLPContract = _rainiLPToken;
      roi[_rainiToken] = 2802790110;
      admin = msg.sender;
  }

  modifier validate(address _validate) {
      require(_validate == rainiTokenContract || _validate == rainiLPContract, "Validation Error : Invalid Staking Asset");
      _;
  }

  modifier hasAccess(){
      require(msg.sender == admin, "Access Control : Caller Not Admin");
      _;
  }

  mapping(uint256 => address) public roi;

  mapping(address => mapping(address => mapping(uint8 => Info ))) public info;
  mapping(address => mapping(address => uint8)) public stakedContracts;
  mapping(address => mapping(address => uint256)) private rewardBalance;

  function stake(address token, uint256 amount) public virtual override validate(token) nonReentrant returns(bool){
      require(
          IERC20(token).allowance(msg.sender, address(this)) >= amount, "Error : Insufficient Allowance"
      );
      require(
          IERC20(token).balanceOf(msg.sender) >= amount, "Error : Insufficient Balance"
      );
      require(
          stakedContracts[msg.sender][token] <= 5, "Max Pool Limit Reached"
      );
      stakedContracts[msg.sender][token] += 1;
      Info storage i = info[msg.sender][token][stakedContracts[msg.sender][token]];
      require(i.staked == 0, "Already Staked");
      i.staked = amount;
      i.timestamp = block.timestamp;
      i.staked = 1;
      IERC20(token).transferFrom(msg.sender,address(this),amount);
      return true;
  }

  function override(address token, uint256 amount, uint8 poolId) public virtual override validate(token) nonReentrant returns(bool){
     require(
          IERC20(token).allowance(msg.sender, address(this)) >= amount, "Error : Insufficient Allowance"
      );
      require(
          IERC20(token).balanceOf(msg.sender) >= amount, "Error : Insufficient Balance"
      );
      Info storage i = info[msg.sender][token][poolId];
      require(
        i.staked == 1, "No Stake Found To Override"
      ); 
      uint256 oldRewards = unclaimed(msg.sender,token,poolId);
      rewardBalance[msg.sender][token] = Math.add(rewardBalance[msg.sender][token],oldReward);
      i.staked = Math.add(i.staked,amount);
      i.timestamp = block.timestamp;
      IERC20(token).transferFrom(msg.sender,address(this),amount);
      return true;
  }

  function unclaimed(address user, address token, uint8 poolId) private override view returns(uint256){
      Info storage i = info[msg.sender][token][poolId];
      uint256 time = Math.sub(i.timestamp,block.timestamp);
      uint256 uncl = Math.mul(i.staked,time);
              uncl = Math.mul(uncl, roi[_token]); 
              uncl = Math.div(uncl, 10 ** 18);
      return uncl; 
  }

  function resolveBonus() private returns(uint8) {
      // Get the Bonus % based on staked duration

  }

  function updateROI(address token, uint256 roi) public virtual hasAccess returns(bool){
      require(roi > 0, "ROI cannot be zero");
      roi[token] = roi;
      return true;
  }

  function transferAccess(address newAdmin) public virtual hasAccess returns(bool){
      require(newAdmin != address(0),"Error : Zero Address");
      admin = newAdmin;
      return true;
  }

  function updateRainiContract(address newContract) public virtual hasAccess returns(bool){
      require(newContract != address(0),"Error : Zero Address");
      rainiTokenContract = newContract;
      return true;
  }

  function updateRainiLPContract(address newContract) public virtual hasAccess returns(bool){
      require(newContract != address(0),"Error : Zero Address");
      rainiLPContract = newContract;
      return true;
  }

}



