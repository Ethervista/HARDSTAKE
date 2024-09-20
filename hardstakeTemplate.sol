// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface IEtherVistaFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function routerSetter() external view returns (address);
    function router() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setRouterSetter(address) external;
    function setRouter(address) external;
}

contract HARDSTAKE is ReentrancyGuard {
    IERC20 public immutable stakingToken;
    address StakingTokenAddress;

    uint256 public constant LOCK_TIME = 21 days;
    uint256 private bigNumber = 10**20;
    uint256 public totalCollected = 0;
    uint256 public poolBalance = 0;
    uint256 public totalSupply = 0; 
    uint256 public cost = 200;
    address private costSetter;
    address private factory;
    AggregatorV3Interface internal priceFeed;

     function getEthUsdcPrice() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price/100); 
    }

    function usdcToEth(uint256 usdcAmount) public view returns (uint256) {
        uint256 ethUsdcPrice = getEthUsdcPrice();
        return (usdcAmount * 1e6*1e18 / ethUsdcPrice); 
    }

    struct Staker {
        uint256 amountStaked;
        uint256 stakingTime;
        uint256 euler0;
    }

    uint256[] public euler; 
    mapping(address => Staker) public stakers;

    constructor(address _stakingToken, address _oracleAddress, address _factory) {
        stakingToken = IERC20(_stakingToken);
        StakingTokenAddress = _stakingToken;
        priceFeed = AggregatorV3Interface(_oracleAddress);
        costSetter = msg.sender;
        factory = _factory;
    }

    function setCost(uint256 _cost) external {
        require(msg.sender == costSetter);
        cost = _cost;
    }

    function updateEuler(uint256 Fee) internal { 
        if (euler.length == 0){
            euler.push((Fee*bigNumber)/totalSupply);
        }else{
            euler.push(euler[euler.length - 1] + (Fee*bigNumber)/totalSupply); 
        }
    }


    function contributeETH() external payable nonReentrant {
        require(msg.value >= usdcToEth(cost), "Insufficient ETH sent");
        poolBalance += msg.value;
        totalCollected += msg.value;
        updateEuler(msg.value);
    }

    function stake(uint256 _amount, address user, address token) external nonReentrant {
        require(msg.sender == IEtherVistaFactory(factory).router(), 'EtherVista: FORBIDDEN');
        require(token == StakingTokenAddress);

        totalSupply += _amount; 

        Staker storage staker = stakers[user];
        staker.amountStaked += _amount; 
        staker.stakingTime = block.timestamp;
        if (euler.length == 0){
            staker.euler0 = 0;
        } else {
            staker.euler0 = euler[euler.length - 1];
        }
    }

    function withdraw(uint256 _amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.amountStaked >= _amount, "Insufficient staked amount");
        require(block.timestamp >= staker.stakingTime + LOCK_TIME, "Tokens are still locked");

        staker.amountStaked -= _amount;
        totalSupply -= _amount; 

        require(stakingToken.transfer(msg.sender, _amount), "Transfer failed");

        if (staker.amountStaked == 0) {
            delete stakers[msg.sender];
        } else {
            staker.stakingTime = block.timestamp;
                if (euler.length == 0){
                    staker.euler0 = 0;
                } else {
                    staker.euler0 = euler[euler.length - 1];
                }
        }
    }

    function claimShare() public nonReentrant {
        require(euler.length > 0, 'EtherVistaPair: Nothing to Claim');
        uint256 balance = stakers[msg.sender].amountStaked;
        uint256 time = stakers[msg.sender].stakingTime;
        uint256 share = (balance * (euler[euler.length - 1] - stakers[msg.sender].euler0))/bigNumber;
        stakers[msg.sender] = Staker(balance, time, euler[euler.length - 1]);
        poolBalance -= share;
        (bool sent,) = payable(msg.sender).call{value: share}("");
        require(sent, "Failed to send Ether");
    }
    
    function viewShare() public view returns (uint256 share) {
        if (euler.length == 0){
            return 0;
        }else{
            return stakers[msg.sender].amountStaked * (euler[euler.length - 1] - stakers[msg.sender].euler0)/bigNumber;
        }
    }

    function getStakerInfo(address _staker) public view returns (
        uint256 amountStaked,
        uint256 timeLeftToUnlock,
        uint256 currentShare
    ) {
        Staker storage staker = stakers[_staker];
        
        amountStaked = staker.amountStaked;
        
        if (block.timestamp < staker.stakingTime + LOCK_TIME) {
            timeLeftToUnlock = (staker.stakingTime + LOCK_TIME) - block.timestamp;
        } else {
            timeLeftToUnlock = 0;
        }
        
        if (euler.length > 0 && staker.amountStaked > 0) {
            currentShare = (staker.amountStaked * (euler[euler.length - 1] - staker.euler0)) / bigNumber;
        } else {
            currentShare = 0;
        }
    }

}
