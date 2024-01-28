// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title BILBOLToken
 * @dev ERC20 token with separate buy and sell transaction fees. 
 * Supports upgradability using the UUPS pattern and includes reentrancy guards.
 */
contract BILBOLToken is ERC20, Ownable, ReentrancyGuard, UUPSUpgradeable {
    uint256 private buyFeePercent = 2; // Initial buy transaction fee percentage
    uint256 private sellFeePercent = 4; // Initial sell transaction fee percentage
    uint256 private constant FEE_DENOMINATOR = 100;

    mapping(address => bool) public feeExempt;

    address public developerWallet;
    address public marketingWallet;

    event FeeExemptUpdated(address indexed account, bool isExempt);
    event WalletsUpdated(address indexed developerWallet, address indexed marketingWallet);
    event FeeUpdated(uint256 buyFeePercent, uint256 sellFeePercent);

    constructor() ERC20("Bilbol", "BBL") Ownable(msg.sender) {
        _mint(msg.sender, 500_000_000 * 10 ** decimals());
        feeExempt[msg.sender] = true;
        developerWallet = msg.sender;
        marketingWallet = msg.sender;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        uint256 fee = _applyFee(msg.sender, recipient, amount);
        _transfer(msg.sender, recipient, amount - fee);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        uint256 fee = _applyFee(sender, recipient, amount);
        _transfer(sender, recipient, amount - fee);
        _spendAllowance(sender, _msgSender(), amount);
        return true;
    }

    function _applyFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (feeExempt[sender]) {
            return 0;
        }

        uint256 feePercent = _isSell(sender, recipient) ? sellFeePercent : buyFeePercent;
        uint256 fee = (amount * feePercent) / FEE_DENOMINATOR;

        _transfer(sender, marketingWallet, fee);

        return fee;
    }

    function _isSell(address sender, address recipient) internal view returns (bool) {
        return sender != address(this) && recipient == address(this);
    }

    function setFeeExempt(address account, bool isExempt) public onlyOwner {
        feeExempt[account] = isExempt;
        emit FeeExemptUpdated(account, isExempt);
    }

    function setFee(uint256 newBuyFeePercent, uint256 newSellFeePercent) public onlyOwner {
        require(newBuyFeePercent <= FEE_DENOMINATOR, "Buy fee percent cannot exceed 100%");
        require(newSellFeePercent <= FEE_DENOMINATOR, "Sell fee percent cannot exceed 100%");
        buyFeePercent = newBuyFeePercent;
        sellFeePercent = newSellFeePercent;
        emit FeeUpdated(newBuyFeePercent, newSellFeePercent);
    }

    function updateWallets(address newDeveloperWallet, address newMarketingWallet) external onlyOwner {
        require(newDeveloperWallet != address(0), "Developer wallet address cannot be zero");
        require(newMarketingWallet != address(0), "Marketing wallet address cannot be zero");
        developerWallet = newDeveloperWallet;
        marketingWallet = newMarketingWallet;
        emit WalletsUpdated(newDeveloperWallet, newMarketingWallet);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}
