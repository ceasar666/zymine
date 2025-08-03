pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
contract Mine is Ownable {
    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant ZY = 0x409e1fB8dcd7092Bd08B08a2c1D2294F1dBa9999;

    address public firstAddr = 0x57a7B58A53C5629DA3BE495Bc68d8fEB5e603348;
    address public marketingAddr = 0x2F7d8cb0C1AFAB35E60692461f337a914b84F2CF;
    address public vault = 0x728c7c0633928aBC4e0a02355d99448258fEfb99;
   
    uint public minAmount = 100 * 1e18;
    uint public maxAmount = 2000 * 1e18;

    uint public ratio1 = 7; //一代推荐奖
    uint public ratio2 = 3; //二代推荐奖
    uint public ratio3 = 30; //销毁
    uint public ratio4 = 50; //vault
    uint public ratio5 = 10; //marketing

    uint public totalStaked;
    uint public slippage = 10; // 买币时的滑点
    bool public start = true;

    struct UserInfo {
        address inviter;
        uint balance15;//质押15天的本金
        uint startTime15; //质押15天的开始时间
        uint balance30;//质押30天的本金
        uint startTime30;//质押30天的开始时间
        uint sons;
        uint rewards;
    }
    mapping(address => UserInfo) public userInfo;
    
    constructor() {
        IERC20(USDT).approve(ROUTER, type(uint).max);
    }

    function setStart(bool _start) external onlyOwner {
        start = _start;
    }
    
    function setMinAndMaxAmount(uint _minAmount, uint _maxAmount) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function setRatios(uint _ratio1, uint _ratio2, uint _ratio3, uint _ratio4, uint _ratio5) external onlyOwner {
        ratio1 = _ratio1;
        ratio2 = _ratio2;
        ratio3 = _ratio3;
        ratio4 = _ratio4;
        ratio5 = _ratio5;
    }

    function setAddrs(address _marketingAddr, address _vault) external onlyOwner {
        marketingAddr = _marketingAddr;
        vault = _vault;
    }

    function setSlippage(uint _slippage) external onlyOwner {
        slippage = _slippage;
    }

    function stake(address inviter, uint usdtAmount, uint lockDays) external {
        require(inviter != msg.sender);
        require(usdtAmount >= minAmount && usdtAmount <= maxAmount);
        require(lockDays == 15 || lockDays == 30);
        UserInfo storage ui = userInfo[msg.sender];
        if (lockDays == 15) {
            require(ui.balance15 == 0);
        } else {
            require(ui.balance30 == 0);
        }
        
        if (ui.inviter == address(0) && inviter != address(0)) {
            ui.inviter = inviter;
            userInfo[inviter].sons++;
            address inviterL2 = userInfo[inviter].inviter;
            if (inviterL2 != address(0)) {
                userInfo[inviterL2].sons++;
            }
        }
        IERC20(USDT).transferFrom(msg.sender, address(this), usdtAmount);
        
        uint rewardL1 = usdtAmount * ratio1 / 100;
        uint rewardL2 = usdtAmount * ratio2 / 100;
        address _inviter = ui.inviter;
        if (_inviter != address(0)) {
            userInfo[_inviter].rewards += rewardL1;
            IERC20(USDT).transfer(_inviter, rewardL1);

            address _inviterL2 = userInfo[_inviter].inviter;
            if (_inviterL2 != address(0)) {
                userInfo[_inviterL2].rewards += rewardL2;
                IERC20(USDT).transfer(_inviterL2, rewardL2); 
            } else {
                IERC20(USDT).transfer(firstAddr, rewardL2);
            }
        } else {
            IERC20(USDT).transfer(firstAddr, rewardL1 + rewardL2);
        }
        
        _buy(usdtAmount * ratio3 / 100);
        IERC20(USDT).transfer(vault, usdtAmount * ratio4 / 100);
        IERC20(USDT).transfer(marketingAddr, usdtAmount * ratio5 / 100);

        if (lockDays == 15) {
            ui.balance15 = usdtAmount;
            ui.startTime15 = block.timestamp;
        } else {
            ui.balance30 = usdtAmount;
            ui.startTime30 = block.timestamp;
        }


        totalStaked += usdtAmount;
    }

    function _buy(uint usdtAmount) private {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = ZY;
        uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(usdtAmount, path);

        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdtAmount,
            amountsOut[1] * (100 - slippage) / 100,
            path,
            address(0),
            block.timestamp
        );
    }

    function zyPrice() public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = ZY;
        path[1] = USDT;
        uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(1e18, path);
        return amountsOut[1];
    }

    function pendingReward15(address user) public view returns (uint) {
       UserInfo storage ui = userInfo[user];
       if (ui.balance15 == 0) return 0;

       uint maxReward = ui.balance15 * 15 / 100;
       if (block.timestamp >= ui.startTime15 + 15 days) {
            return maxReward;
       } else {
            uint rewardPerSec = ui.balance15 / 100 / 86400;
            return rewardPerSec * (block.timestamp - ui.startTime15); 
       }
    }

    function pendingReward30(address user) public view returns (uint) {
       UserInfo storage ui = userInfo[user];
       if (ui.balance30 == 0) return 0;

       uint maxReward = ui.balance30 * 36 / 100;
       if (block.timestamp >= ui.startTime30 + 30 days) {
            return maxReward;
       } else {
            uint rewardPerSec = ui.balance30 * 12 / 1000 / 86400;
            return rewardPerSec * (block.timestamp - ui.startTime30); 
       }
    }

    function claim15() external {
        UserInfo storage ui = userInfo[msg.sender];
        require(block.timestamp >= ui.startTime15 + 15 days);
        uint pending = pendingReward15(msg.sender);
        require(pending > 0, "No pending reward");

        ui.balance15 = 0;
        ui.startTime15 = 0;

        uint tokenAmount = pending * 1e18 / zyPrice();
        IERC20(ZY).transferFrom(vault, msg.sender, tokenAmount);
    }

    function claim30() external {
        UserInfo storage ui = userInfo[msg.sender];
        require(block.timestamp >= ui.startTime30 + 30 days);
        uint pending = pendingReward30(msg.sender);
        require(pending > 0, "No pending reward");

        ui.balance30 = 0;
        ui.startTime30 = 0;

        uint tokenAmount = pending * 1e18 / zyPrice();
        IERC20(ZY).transferFrom(vault, msg.sender, tokenAmount);
    }

    function rescueETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function rescueERC20(address token, address to, uint amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}