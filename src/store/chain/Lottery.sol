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

interface IToken {
    function rewardTo(address to, uint amount) external;
}

contract Lottery is Ownable {
    struct UserInfo {
        address inviter;
        uint burned;
        uint sons;
        uint rewards; //总奖励
    }
    mapping(address => UserInfo) public userInfo;
    uint public referralL1 = 3;
    uint public referralL2 = 2;

    struct ItemInfo {
        address account;
        uint amount;//参与金额
        uint time; //时间
        uint blockNum;//区块高度
        uint status; // 0 开奖中， 1 末中奖， 2 已中奖
        bytes32 nextBlockHash;
    }
    mapping (uint => ItemInfo) public itemInfoByIndex;
    mapping(address => uint[]) public indexesOf;

    uint public totalItemNum;
    uint public lastProcessItemIndex;
    uint public rewardRatio = 196;

    address public TOKEN = 0xE671B3F7543F583D087E9A2AF7046a9f763C87a8;

    struct Rank {
        address user;
        uint256 amount;
    }
    
    // 前10名数组
    Rank[10] public top10;

    function init(address _TOKEN) public onlyOwner {
        TOKEN = _TOKEN;
    }

    function setRewardRatio(uint _referralL1, uint _referralL2) public onlyOwner {
        referralL1 = _referralL1;
        referralL2 = _referralL2;
    }

    function setRewardArgs(uint _rewardRatio) public onlyOwner {
        rewardRatio = _rewardRatio;
    }

    /**哈希池 */
    function burn(address inviter, uint amount) external {
        require(inviter != msg.sender);
        require(amount >= 1e18);

        UserInfo storage ui = userInfo[msg.sender];
        if (ui.inviter == address(0) && inviter != address(0)) {
            ui.inviter = inviter;
            userInfo[inviter].sons++;
            address _inviterL2 = userInfo[inviter].inviter;
            if (_inviterL2 != address(0)) {
                userInfo[_inviterL2].sons++;
            }
        }

        amount = amount / 1e18 * 1e18;
        ui.burned += amount;
        uint rL1;
        uint rL2;
        address inviterL1 = ui.inviter;
        if (inviterL1 != address(0)) {
            rL1 = amount * referralL1 / 100;
            userInfo[inviterL1].rewards += rL1;
            IERC20(TOKEN).transferFrom(msg.sender, inviterL1, rL1);

            address inviterL2 = userInfo[inviterL1].inviter;
            if (inviterL2 != address(0)) {
                rL2 = amount * referralL2 / 100;
                userInfo[inviterL2].rewards += rL2;
                IERC20(TOKEN).transferFrom(msg.sender, inviterL2, rL2);
            } 
        }
         
        IERC20(TOKEN).transferFrom(msg.sender, address(0xdead), amount - rL1 - rL2);

        totalItemNum++;
        ItemInfo memory ii;
        ii.account = msg.sender;
        ii.amount = amount;
        ii.blockNum = block.number;
        ii.time = block.timestamp;
        ii.status = 0;
        itemInfoByIndex[totalItemNum] = ii;
        indexesOf[msg.sender].push(totalItemNum);

        _updataTop10(msg.sender, ui.burned);
	}

    function _updataTop10(address user, uint newAmount) private {
        // 检查用户是否已在排行榜中
        int256 existingIndex = -1;
        for (uint i = 0; i < 10; i++) {
            if (top10[i].user == user) {
                existingIndex = int256(i);
                break;
            }
        }
        // 用户已在排行榜中
        if (existingIndex >= 0) {
            top10[uint256(existingIndex)].amount = newAmount;
            _bubbleUp(uint256(existingIndex));
            return;
        }

        // 新用户尝试进入排行榜
        if (newAmount > top10[9].amount) {
            top10[9] = Rank(user, newAmount);
            _bubbleUp(9);
        }
    }

    // 向上冒泡（金额增加时）
    function _bubbleUp(uint256 index) private {
        while (index > 0 && top10[index].amount > top10[index-1].amount) {
            // 交换位置
            Rank memory temp = top10[index-1];
            top10[index-1] = top10[index];
            top10[index] = temp;
            index--;
        }
    }

    // 获取整个排行榜
    function getTop10() external view returns (Rank[10] memory) {
        return top10;
    }

    function processLottery() external {
        bytes32 zeroHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        uint _lastProcessItemIndex = lastProcessItemIndex;
        for (uint i; i < 10; i++) {
            _lastProcessItemIndex++;
            if (_lastProcessItemIndex > totalItemNum) {
                _lastProcessItemIndex = totalItemNum;
                break;
            }
            ItemInfo storage ii = itemInfoByIndex[_lastProcessItemIndex];
            if (block.number <= ii.blockNum + 1) {
                _lastProcessItemIndex--;
                break;
            }
            bytes32 nextBlockHash = blockhash(ii.blockNum + 1);
            ii.nextBlockHash = nextBlockHash;
            if (nextBlockHash == zeroHash) {
                continue;
            }
            bytes1 lastDigit = nextBlockHash[31];
            uint8 lastDigitNum = uint8(lastDigit) & 0x0F;

            uint lastDigitOfAmount = (ii.amount / 1e18) % 2;
            
            if ((lastDigitNum % 2) == lastDigitOfAmount) {
                uint reward = ii.amount * rewardRatio / 100;
                IToken(TOKEN).rewardTo(ii.account, reward);
                ii.status = 2;
            } else {
                ii.status = 1;
            }
        }
        lastProcessItemIndex = _lastProcessItemIndex;
    }

    function rescurToken(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function rescueETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function viewBalanceOfThis(address token) public view returns(uint){
       return IERC20(token).balanceOf(address(this)); 
    }

    function getItemsLenOf(address user) public view returns (uint) {
        return indexesOf[user].length;
    }

    function getUserItems(address user) public view returns (ItemInfo[] memory) {
        uint[] memory indexes = indexesOf[user];
        uint len = indexes.length;
        uint start;
        if (len > 10) {
            start = len - 10;
        }
        uint num = len - start;
        ItemInfo[] memory items = new ItemInfo[](num);
        uint j = 0;
        for (uint i = start; i < len; i++) {
            uint index = indexes[i];
            ItemInfo storage ii = itemInfoByIndex[index];
            items[j].account = ii.account;
            items[j].amount = ii.amount;
            items[j].time = ii.time;
            items[j].blockNum = ii.blockNum;
            items[j].status = ii.status;
            items[j].nextBlockHash = ii.nextBlockHash;
            j++;
        }
        return items;
    }
}