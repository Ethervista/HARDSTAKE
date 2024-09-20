// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

interface IEtherVistaPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function setMetadata(string calldata website, string calldata image, string calldata description, string calldata chat, string calldata social) external; 
    function websiteUrl() external view returns (string memory);
    function imageUrl() external view returns (string memory);
    function tokenDescription() external view returns (string memory);
    function chatUrl() external view returns (string memory);
    function socialUrl() external view returns (string memory);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function updateProvider(address user) external;
    function euler(uint) external view returns (uint256);
    function viewShare() external view returns (uint256 share);
    function claimShare() external;
    function poolBalance() external view returns (uint);
    function totalCollected() external view returns (uint);
    
    function setProtocol(address) external;
    function protocol() external view returns (address);
    function payableProtocol() external view returns (address payable origin);

    function creator() external view returns (address);
    function renounce() external;

    function setFees() external;
    function updateFees(uint8, uint8, uint8, uint8) external;
    function buyLpFee() external view returns (uint8);
    function sellLpFee() external view returns (uint8);
    function buyProtocolFee() external view returns (uint8);
    function sellProtocolFee() external view returns (uint8);
    function buyTotalFee() external view returns (uint8);
    function sellTotalFee() external view returns (uint8);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function first_mint(address to, uint8 buyLp, uint8 sellLp, uint8 buyProtocol, uint8 sellProtocol, address protocolAddress) external returns (uint liquidity);   
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address _token0, address _token1) external;
}

interface IEtherVistaRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
    ) external returns (uint amountETH);
 
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function launch(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint8 buyLpFee, 
        uint8 sellLpFee, 
        uint8 buyProtocolFee, 
        uint8 sellProtocolFee, 
        address protocolAddress
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function updateSelf(address _token) external;

    function safeTransferLp(address _token, address to, uint256 _amount) external;

    function hardstake(address _contract, address _token,  uint256 _amount) external; 
}

contract HARDSTAKE is ReentrancyGuard {
    IERC20 public immutable stakingToken;
    address StakingTokenAddress;

    uint256 public constant LOCK_TIME = 21 days;
    uint256 private bigNumber = 10**20;
    uint256 public totalCollected = 0;
    uint256 public poolBalance = 0;
    uint256 public totalSupply = 0; 
    address private factory;

    struct Staker {
        uint256 amountStaked;
        uint256 stakingTime;
        uint256 euler0;
    }

    uint256[] public euler; 
    mapping(address => Staker) public stakers;

    constructor(address _stakingToken, address _factory) {
        stakingToken = IERC20(_stakingToken);
        StakingTokenAddress = _stakingToken;
        factory = _factory;
    }

    //everytime claimShare() is called from the pair, this receive() function will update the euler variable from this contract
    //which is used to keep track of a staker's share of rewards
    receive() external payable {
        poolBalance += msg.value;
        totalCollected += msg.value;
        updateEuler(msg.value);
    }

    function updateEuler(uint256 Fee) internal { 
        if (euler.length == 0){
            euler.push((Fee*bigNumber)/totalSupply);
        }else{
            euler.push(euler[euler.length - 1] + (Fee*bigNumber)/totalSupply); 
        }
    }

    function stake(uint256 _amount, address user, address token) external nonReentrant {
        require(msg.sender == IEtherVistaFactory(factory).router(), 'EtherVista: FORBIDDEN');
        require(token == StakingTokenAddress);

        IEtherVistaPair pair = IEtherVistaPair(token);
        uint256 share = pair.viewShare();
        if (share == 0) {
            IEtherVistaRouter(IEtherVistaFactory(factory).router()).updateSelf(token);
        } else {
            pair.claimShare(); 
        }

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

    //Staker must claim rewards before whitdrawing
    //User should be immediatly prompted to call updateSelf() immediatly after whitdrawing
    function withdraw(uint256 _amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(staker.amountStaked >= _amount, "Insufficient staked amount");
        require(block.timestamp >= staker.stakingTime + LOCK_TIME, "Tokens are still locked");

        totalSupply -= _amount; 
        staker.amountStaked -= _amount;

        stakingToken.approve(IEtherVistaFactory(factory).router(), _amount);
        IEtherVistaRouter(IEtherVistaFactory(factory).router()).safeTransferLp(StakingTokenAddress, msg.sender, _amount);
        //Router will safely update this contract's share of rewards when transfering LPs back to the staker

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
        IEtherVistaPair pair = IEtherVistaPair(StakingTokenAddress);
        uint256 contractShare = pair.viewShare();
        if (contractShare > 0) {
            pair.claimShare(); //else user will miss on rewards that belong to him
        }
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


