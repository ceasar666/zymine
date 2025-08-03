//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IToken {
    function reSync(uint amount) external;
}

contract Pool is Ownable {
    struct ItemInfo {
        address account;
        uint amount;//参与金额
        uint startTime; //开始时间
        uint lockDays; //天数
        bool isOut; //是否已赎回
    }
    mapping (uint => ItemInfo) public itemInfoByIndex;
    struct UserInfo {
        address inviter;
        uint totalIn;
        uint vipLevel;//等级, 1-5
        uint score; //总业绩
        uint sons;
        uint rewards; //已获奖励
        uint[] indexesOf;
    }
    mapping(address => UserInfo) public userInfo;

    uint public totalItemNum;
    uint public totalStaked;
    
    address public BXC;
    address constant public ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address constant public USDT = 0x0FB3c077479113dF18f9f51Dc282b09bB0461000;
    address public vault = 0x9Ee20a74588A1D89e028a2be4CCF842ac9352111;
    address public firstAddr = 0x9Ee20a74588A1D89e028a2be4CCF842ac9352111;

    uint public maxToken = 1000 * 1e18;
    uint public minTokenForReferral = 200 * 1e18;
    uint public loop = 20;

    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant WAD = 1e18;
    

    constructor() {
        IERC20(USDT).approve(ROUTER, type(uint).max);
    }

    function init(address bxc) public onlyOwner {
        BXC = bxc;
        IERC20(bxc).approve(ROUTER, type(uint).max);
    }

    function setMaxToken(uint _maxToken) external onlyOwner {
        maxToken = _maxToken;
    }

    function setLoop(uint _loop) external onlyOwner {
        loop = _loop;
    }

    function setMinTokenForReferral(uint _minTokenForReferral) external onlyOwner {
        minTokenForReferral = _minTokenForReferral;
    }

    function isValidInviter(address user, address inviter) public view returns (bool) {
        if (inviter == firstAddr 
            || userInfo[user].inviter != address(0)
            || (userInfo[inviter].inviter != address(0) && userInfo[inviter].totalIn >= minTokenForReferral)
        ) {
            return true;
        } else {
            return false;
        } 
    }

    function stake(address inviter, uint usdAmount, uint lockDays) external {
        require(tx.origin == msg.sender);
        require(isValidInviter(msg.sender, inviter));
        require(usdAmount >= 1e18 && usdAmount <= maxToken);
        require(lockDays == 1 || lockDays == 15 || lockDays == 30);
        UserInfo storage ui = userInfo[msg.sender];
        ui.totalIn += usdAmount;
        
        if (ui.inviter == address(0)) {
            ui.inviter = inviter;
            userInfo[inviter].sons++;
        }
 
        IERC20(USDT).transferFrom(msg.sender, address(this), usdAmount);
        uint half = usdAmount / 2;
        uint bb = IERC20(BXC).balanceOf(address(this));
        _buy(half);
        uint tokenAmount = IERC20(BXC).balanceOf(address(this)) - bb;
        _addLiquidity(tokenAmount, half);
        
        totalItemNum++;
        ItemInfo memory ii;
        ii.account = msg.sender;
        ii.amount = usdAmount;
        ii.lockDays = lockDays;
        ii.startTime = block.timestamp;
        ii.isOut = false;
        itemInfoByIndex[totalItemNum] = ii;
        ui.indexesOf.push(totalItemNum);

        _updateLevel(msg.sender, usdAmount);
	}

    function _buy(uint usdtAmount) private {
        // generate the uniswap pair path of token -> usdt
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = BXC;

        // make the swap
        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdtAmount,
            0, // accept any amount of USDT
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint tokenAmount, uint usdtAmount) private {
        IRouter(ROUTER).addLiquidity(
            BXC,
            USDT,
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _updateLevel(address user, uint usdAmount) private {
        UserInfo storage ui = userInfo[user];
        for (uint8 i; i < loop; i++) {
            address inviter = ui.inviter;
            if (inviter != address(0)) {
                UserInfo storage uiI = userInfo[inviter];
                uiI.score += usdAmount;
                __updateLevel(inviter);
            }
        }
    }

    function __updateLevel(address user) private {
        UserInfo storage ui = userInfo[user];
        if (ui.score >= 100 * 1e22) {
            if (ui.vipLevel < 5) {
                ui.vipLevel = 5;
            }
        } else if (ui.score >= 50 * 1e22) {
            if (ui.vipLevel < 4) {
                ui.vipLevel = 4;
            }
        } else if (ui.score >= 10 * 1e22) {
            if (ui.vipLevel < 3) {
                ui.vipLevel = 3;
            }
        } else if (ui.score >= 5 * 1e22) {
            if (ui.vipLevel < 2) {
                ui.vipLevel = 2;
            }
        } else if (ui.score >= 1 * 1e22) {
            if (ui.vipLevel < 1) {
                ui.vipLevel = 1;
            }
        }
    }

    function pendingReward(uint index) public view returns (uint) {
       ItemInfo storage ii = itemInfoByIndex[index];
       if (ii.amount == 0 || ii.isOut) return 0;

       uint rate = WAD * 3 / 1000;
       uint maxTime = 1 days; 
       if (ii.lockDays == 15) {
            rate = WAD * 6 / 1000;
            maxTime = 15 days; 
       } else if (ii.lockDays == 30) {
            rate = WAD * 12 / 1000;
            maxTime = 30 days; 
       }

       uint compRate = calculateCompoundedRate(rate, ii.startTime, block.timestamp, maxTime);
       return ii.amount * compRate / WAD; 
    }
    
    function calculateCompoundedRate(
        uint256 rate,
        uint256 lastUpdateTimestamp,
        uint256 currentTimestamp,
        uint256 maxTime
    ) public pure returns (uint256) {
        uint256 exp = currentTimestamp - lastUpdateTimestamp;

        if (exp == 0) {
            return WAD;
        }

        if (exp > maxTime) {
            exp = maxTime;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo = rate * rate / (SECONDS_PER_DAY * SECONDS_PER_DAY) / WAD;
            basePowerThree = basePowerTwo * rate / SECONDS_PER_DAY / WAD;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return WAD + (rate * exp) / SECONDS_PER_DAY + secondTerm + thirdTerm;
    }

    function claim(uint index) external {
        require(tx.origin == msg.sender);
        ItemInfo storage ii = itemInfoByIndex[index];
        require(ii.account == msg.sender);
        require(block.timestamp >= ii.startTime + ii.lockDays * 1 days);
        uint reward = pendingReward(index);
        require(reward > 0);
        ii.isOut = true;
        
        uint bb = IERC20(USDT).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = BXC;
        path[1] = USDT;
        uint bbToken = IERC20(BXC).balanceOf(address(this));
        IRouter(ROUTER).swapTokensForExactTokens(
            reward, 
            bbToken, 
            path, 
            address(this), 
            block.timestamp
        );
        uint spentToken = bbToken - IERC20(BXC).balanceOf(address(this));
        uint newBalance = IERC20(USDT).balanceOf(address(this)) - bb;
        uint profit = newBalance - ii.amount;
        IERC20(USDT).transfer(msg.sender, newBalance - profit * 25 / 100);
        _processReferral(msg.sender, profit);
        IToken(BXC).reSync(spentToken);
    }

    function _processReferral(address user, uint profit) private {
        uint bb = IERC20(USDT).balanceOf(address(this));
        UserInfo storage ui = userInfo[user];
        if (ui.inviter != address(0)) {
            uint rL0 = profit * 5 / 100;
            userInfo[ui.inviter].rewards += rL0;
            IERC20(USDT).transfer(ui.inviter, rL0);
        }

        address _inviter = user;
        uint _prevLevel;
        address[] memory rewardList = new address[](5);
        uint index;
        for (uint8 i; i < loop; i++) {
            _inviter = userInfo[_inviter].inviter;
            if (_inviter == address(0)) {
                break;
            }
                
            //rewards
            uint levelOf = userInfo[_inviter].vipLevel;
            if (levelOf > _prevLevel && index < 5) {
                rewardList[index] = _inviter;
                index++;
                _prevLevel = levelOf;
            }
        }
        if (index == 0) 
            return;
        address _firstAddr = rewardList[0];
        uint firstAddrLevel = userInfo[_firstAddr].vipLevel;
        if (firstAddrLevel == 1) {
            userInfo[_firstAddr].rewards += profit * 4 / 100;
            IERC20(USDT).transfer(_firstAddr, profit * 4 / 100);
        } else if(firstAddrLevel == 2) {
            userInfo[_firstAddr].rewards += profit * 8 / 100;
            IERC20(USDT).transfer(_firstAddr, profit * 8 / 100);
        } else if(firstAddrLevel == 3) {
            userInfo[_firstAddr].rewards += profit * 12 / 100;
            IERC20(USDT).transfer(_firstAddr, profit * 12 / 100);
        } else if(firstAddrLevel == 4) {
            userInfo[_firstAddr].rewards += profit * 16 / 100;
            IERC20(USDT).transfer(_firstAddr, profit * 16 / 100);
        } else if(firstAddrLevel == 5) {
            userInfo[_firstAddr].rewards += profit * 20 / 100;
            IERC20(USDT).transfer(_firstAddr, profit * 20 / 100);
            return;
        }
        for (uint8 i = 1; i < index; i++) {
            address temp = rewardList[i];
            uint curLevel = userInfo[temp].vipLevel;
            uint diff = curLevel - firstAddrLevel;
            userInfo[temp].rewards += profit * diff * 4 / 100;
            IERC20(USDT).transfer(temp, profit * diff * 4 / 100);
            firstAddrLevel = curLevel;
        }
        uint ba = IERC20(USDT).balanceOf(address(this));
        if (bb - ba < profit * 25 / 100) {
            uint left = profit * 25 / 100 - (bb - ba);
            IERC20(USDT).transfer(vault, left);
        }
    }

    function rescurToken(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function rescueETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function getUserItems(address user) public view returns (ItemInfo[] memory, uint[] memory, uint[] memory) {
        UserInfo storage ui = userInfo[user];
        uint[] memory indexes = ui.indexesOf;

        uint len = indexes.length;
        ItemInfo[] memory items = new ItemInfo[](len);
        uint[] memory rewards = new uint[](len);
        for (uint8 i; i < len; i++) {
            uint index = indexes[i];
            ItemInfo storage ii = itemInfoByIndex[index];
            items[i].account = ii.account;
            items[i].amount = ii.amount;
            items[i].startTime = ii.startTime;
            items[i].lockDays = ii.lockDays;
            items[i].isOut = ii.isOut;

            rewards[i] = pendingReward(index);
        }
        return (items, rewards, indexes);
    }

    function getUserItemIndexes(address user) public view returns(uint[] memory) {
        UserInfo storage ui = userInfo[user];
        return ui.indexesOf;
    }

    function getTotalBalance(address user) public view returns (uint) {
        UserInfo storage ui = userInfo[user];
        uint[] memory indexes = ui.indexesOf;

        uint len = indexes.length;
        uint totalBalance;
        for (uint8 i; i < len; i++) {
            uint index = indexes[i];
            ItemInfo storage ii = itemInfoByIndex[index];
            if (!ii.isOut) {
                totalBalance += pendingReward(index);
            }
        }
        return totalBalance;
    }
}