// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BILBOLToken.sol"; // Assuming BILBOLToken is in a separate file
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BettingPool is Ownable, ReentrancyGuard {
    IUniswapV2Router02 public uniswapRouter;
    BILBOLToken public bilbolToken;
    mapping(address => uint256) public bets;
    address public winner;
    uint256 public totalPool;
    address private developerWallet;
    bool private distributionDone;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // WETH address for Goerli

    // Event declarations
    event BetPlaced(address indexed bettor, uint256 amount);
    event WinnerSet(address indexed winner);
    event WinningsDistributed(uint256 winnerShare, uint256 developerShare);

    constructor(address _tokenAddress, address _developerWallet, address _uniswapRouterAddress) Ownable(msg.sender) {
        bilbolToken = BILBOLToken(_tokenAddress);
        developerWallet = _developerWallet;
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }

    function placeBet(uint256 amount) public {
        require(amount > 0, "Bet amount must be greater than 0");
        require(bilbolToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        bets[msg.sender] += amount;
        totalPool += amount;
        emit BetPlaced(msg.sender, amount);
    }

    function setWinner(address _winner) public onlyOwner {
        require(_winner != address(0), "Invalid winner address");
        require(!distributionDone, "Distribution already done");
        winner = _winner;
        emit WinnerSet(winner);
    }

    function swapBBLForETH(uint256 bblAmount) public onlyOwner {
    // Ensure the contract has enough BBL tokens to swap
    require(bilbolToken.balanceOf(address(this)) >= bblAmount, "Insufficient BBL tokens");

    // Approve the Uniswap Router to spend BBL tokens
    bilbolToken.approve(address(uniswapRouter), bblAmount);

    // Set up the swap parameters
    address[] memory path = new address[](2);
uard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BILBOLToken.sol"; // Assuming BILBOLToken is in a separate file
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BettingPool is Ownable, ReentrancyGuard {
    IUniswapV2Router02 public uniswapRouter;
    BILBOLToken public bilbolToken;
    mapping(address => uint256) public bets;
    address public winner;
    uint256 public totalPool;
    address private developerWallet;
    bool private distributionDone;
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // WETH address for Goerli

    // Event declarations
    event BetPlaced(address indexed bettor, uint256 amount);
    event WinnerSet(address indexed winner);
    event WinningsDistributed(uint256 winnerShare, uint256 developerShare);

    constructor(address _tokenAddress, address _developerWallet, address _uniswapRouterAddress) Ownable(msg.sender) {
        bilbolToken = BILBOLToken(_tokenAddress);
        developerWallet = _developerWallet;
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }

    function placeBet(uint256 amount) public {
        require(amount > 0, "Bet amount must be greater than 0");
        require(bilbolToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        bets[msg.sender] += amount;
        totalPool += amount;
        emit BetPlaced(msg.sender, amount);
    }

    function setWinner(address _winner) public onlyOwner {
        require(_winner != address(0), "Invalid winner address");
        require(!distributionDone, "Distribution already done");
        winner = _winner;
        emit WinnerSet(winner);
    }

    function swapBBLForETH(uint256 bblAmount) public onlyOwner {
    // Ensure the contract has enough BBL tokens to swap
    require(bilbolToken.balanceOf(address(this)) >= bblAmount, "Insufficient BBL tokens");

    // Approve the Uniswap Router to spend BBL tokens
    bilbolToken.approve(address(uniswapRouter), bblAmount);

    // Set up the swap parameters
    address[] memory path = new address[](2);
    path[0] = address(bilbolToken);
    path[1] = uniswapRouter.WETH();

    // Execute the swap using swapExactTokensForETHSupportingFeeOnTransferTokens
    uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        bblAmount,
        0, // Accept any amount of ETH
        path,
        address(this),
        block.timestamp
    );
}

    function distributeWinnings() public nonReentrant {
        require(winner != address(0), "Winner not determined");

        // Swap the entire totalPool of BBL for ETH
        swapBBLForETH(totalPool);

        // Calculate the shares after the swap
        uint256 ethBalance = address(this).balance;
        uint256 winnerShare = ethBalance * 80 / 100; // 80% to the winner
        uint256 developerShare = ethBalance - winnerShare; // Remaining to the developer

        // Ensure the contract has enough ETH after the swap
        require(ethBalance >= winnerShare + developerShare, "Insufficient ETH balance");

        // Transfer ETH shares
        payable(winner).transfer(winnerShare);
        payable(developerWallet).transfer(developerShare);

        emit WinningsDistributed(winnerShare, developerShare);

        // Reset totalPool and distribution flag
        totalPool = 0;
        distributionDone = true;
    }

    

    receive() external payable {
        // No specific logic required, simply receive and store Ether in the contract
    }

    function getBBLBalance() public view returns (uint256) {
    return bilbolToken.balanceOf(address(this));
}

    // Function to deposit ETH into the contract (onlyOwner)
    function depositEth(uint256 amount) public payable onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value == amount, "Sent Ether does not match the specified amount");
        // No specific logic required, simply deposit the specified amount of ETH into the contract
    }

    // Function to deposit BBL tokens into the contract (onlyOwner)
    function depositBBL(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(bilbolToken.transferFrom(msg.sender, address(this), amount), "BBL Transfer failed");
    }


    // Additional functions and logic here (if any)

    // UniSwap DEX integration to swap winning shares to Ethereum before distribution
}
