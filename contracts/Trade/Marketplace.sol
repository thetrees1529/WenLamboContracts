//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@thetrees1529/solutils/contracts/payments/ERC20Payments.sol";

interface IWAVAX {
    function withdraw(uint wad) external;
}

contract Marketplace is Ownable, ReentrancyGuard {
    using ERC20Payments for IERC20;

    IWAVAX public WAVAX;

    struct UniversalOrder{
        address user;

        IERC721 col;

        IERC20 token;
        uint amount;

        uint expiry;
    }

    struct Order {
        address user;

        IERC721 col;
        uint tokenId;

        IERC20 token;
        uint amount;

        uint expiry;
    }

    event Whitelisted(IERC721 col);
    event Blacklisted(IERC721 col);

    event TokenWhitelisted(IERC20 token);
    event TokenBlacklisted(IERC20 token);

    event Listed(uint listingId, Order order);
    event Offered(uint offerId, Order order);
    event UniversallyOffered(uint universalOfferId, UniversalOrder order);

    event Delisted(uint listingId);
    event OfferCancelled(uint offerId);
    event UniversalOfferCancelled(uint universalOfferId);

    event Bought(uint listingId, address buyer);
    event OfferAccepted(uint offerId, address seller);
    event UniversalOfferAccepted(uint universalOfferId, address seller, uint tokenId);

    mapping(uint => Order) private _offers;
    mapping(uint => Order) private _listings;
    mapping(uint => UniversalOrder) private _universalOffers;
    mapping(IERC721 => bool) private _supportedCollections;
    mapping(IERC20 => bool) private _allowedTokens;

    uint public miliFee;
    address public feeRecipient;

    constructor(IWAVAX WAVAX_) {
        WAVAX = WAVAX_;
        _whitelistToken(IERC20(address(WAVAX_)));
    }

    function setFee(uint miliFee_) external nonReentrant onlyOwner {
        miliFee = miliFee_;
    }

    function setFeeRecipient(address feeRecipient_) external nonReentrant onlyOwner {
        feeRecipient = feeRecipient_;
    }

    function whitelist(IERC721 col) external onlyOwner nonReentrant {
        require(!_supportedCollections[col], "Marketplace: already whitelisted");
        _supportedCollections[col] = true;
        emit Whitelisted(col);
    }

    function blacklist(IERC721 col) external onlyOwner nonReentrant {
        require(_supportedCollections[col], "Marketplace: already blacklisted");
        _supportedCollections[col] = false;
        emit Blacklisted(col);
    }

    function whitelistToken(IERC20 token) external onlyOwner nonReentrant {
        _whitelistToken(token);
    }

    function blacklistToken(IERC20 token) external onlyOwner nonReentrant {
        require(_allowedTokens[token], "Marketplace: token already blacklisted");
        _allowedTokens[token] = false;
        emit TokenBlacklisted(token);
    }

    struct ListArgs {
        IERC721 col;
        uint tokenId;
        IERC20 token;
        uint amount;
        uint expiry;
    }

    function multiList(ListArgs[] calldata args) external {
        for(uint i; i < args.length; i ++) {
            ListArgs calldata arg = args[i];
            list(arg.col, arg.tokenId, arg.token, arg.amount, arg.expiry);
        }
    }

    function list(IERC721 col, uint tokenId, IERC20 token, uint amount, uint expiry) public nonReentrant onlyWhitelisted(col) onlyWhitelistedToken(token){
        _onlyOwnerOf(col, tokenId);
        uint listingId = _newId();
        Order storage listing = _listings[listingId] = Order(msg.sender, col, tokenId, token, amount, expiry);

        emit Listed(listingId, listing);
    }

    function multiDelist(uint[] calldata listingIds) external {
        for(uint i; i < listingIds.length; i ++) {
            delist(listingIds[i]);
        }
    }

    function delist(uint listingId) public nonReentrant {
        Order storage listing = _listings[listingId];
        require(listing.user == msg.sender, "Marketplace: not seller");
        delete _listings[listingId];

        emit Delisted(listingId);
    }

    struct OfferArgs {
        IERC721 col;
        uint tokenId;
        IERC20 token;
        uint amount;
        uint expiry;
    }

    function multiOffer(OfferArgs[] calldata args) external {
        for(uint i; i < args.length; i ++) {
            OfferArgs calldata arg = args[i];
            offer(arg.col, arg.tokenId, arg.token, arg.amount, arg.expiry);
        }
    }

    function offer(IERC721 col, uint tokenId, IERC20 token, uint amount, uint expiry) public nonReentrant onlyWhitelisted(col) onlyWhitelistedToken(token) {
        uint offerId = _newId();
        Order storage offer_ = _offers[offerId] = Order(msg.sender, col, tokenId, token, amount, expiry);
        emit Offered(offerId, offer_);
    }

    function multiCancelOffer(uint[] calldata offerIds) external {
        for(uint i; i < offerIds.length; i ++) {
            cancelOffer(offerIds[i]);
        }
    }

    function cancelOffer(uint offerId) public nonReentrant {
        Order storage offer_ = _offers[offerId];
        require(offer_.user == msg.sender, "Marketplace: not offerer");
        delete _offers[offerId];

        emit OfferCancelled(offerId);
    }

    struct UniversalOfferArgs {
        IERC721 col;
        IERC20 token;
        uint amount;
        uint expiry;
    }

    function multiUniversallyOffer(UniversalOfferArgs[] calldata args) external {
        for(uint i; i < args.length; i ++) {
            UniversalOfferArgs calldata arg = args[i];
            universallyOffer(arg.col, arg.token, arg.amount, arg.expiry);
        }
    }

    function universallyOffer(IERC721 col, IERC20 token, uint amount, uint expiry) public nonReentrant onlyWhitelisted(col) onlyWhitelistedToken(token) {
        uint universalOfferId = _newId();
        UniversalOrder storage universalOffer = _universalOffers[universalOfferId] = UniversalOrder(msg.sender, col, token, amount, expiry);

        emit UniversallyOffered(universalOfferId, universalOffer);
    }

    function multiCancelUniversalOffer(uint[] calldata universalOfferIds) external {
        for(uint i; i < universalOfferIds.length; i ++) {
            cancelUniversalOffer(universalOfferIds[i]);
        }
    }

    function cancelUniversalOffer(uint universalOfferId) public nonReentrant {
        UniversalOrder storage universalOffer = _universalOffers[universalOfferId];
        require(universalOffer.user == msg.sender, "Marketplace: not offerer");
        delete _universalOffers[universalOfferId];

        emit UniversalOfferCancelled(universalOfferId);
    }

    function multiBuy(uint[] calldata listingIds) external payable {
        for(uint i; i < listingIds.length; i ++) {
            buy(listingIds[i]);
        }
    }

    function buy(uint listingId) public payable nonReentrant {
        Order storage listing = _listings[listingId];
        require(listing.user != address(0), "Marketplace: listing not found");
        require(block.timestamp < listing.expiry, "Marketplace: listing expired");

        _transferFunds(listing.token, msg.sender, listing.user, listing.amount);
        listing.col.safeTransferFrom(listing.user, msg.sender, listing.tokenId);

        delete _listings[listingId];
        emit Bought(listingId, msg.sender);
    }

    function multiAcceptOffer(uint[] calldata offerIds) external  {
        for(uint i; i < offerIds.length; i ++) {
            acceptOffer(offerIds[i]);
        }
    }

    function acceptOffer(uint offerId) public nonReentrant {
        Order storage offer_ = _offers[offerId];
        _onlyOwnerOf(offer_.col, offer_.tokenId);
        require(offer_.user != address(0), "Marketplace: offer not found");
        require(block.timestamp < offer_.expiry, "Marketplace: offer expired");

        _transferFunds(offer_.token, offer_.user, msg.sender, offer_.amount);
        offer_.col.safeTransferFrom(msg.sender, offer_.user, offer_.tokenId);

        delete _offers[offerId];
        emit OfferAccepted(offerId, msg.sender);
    }

    struct AcceptUniversalOfferArgs {
        uint universalOfferId;
        uint tokenId;
    }

    function multiAcceptUniversalOffer(AcceptUniversalOfferArgs[] calldata args) external {
        for(uint i; i < args.length; i ++) {
            AcceptUniversalOfferArgs calldata arg = args[i];
            acceptUniversalOffer(arg.universalOfferId, arg.tokenId);
        }
    }

    function acceptUniversalOffer(uint universalOfferId, uint tokenId) public nonReentrant {
        UniversalOrder storage universalOffer = _universalOffers[universalOfferId];
        _onlyOwnerOf(universalOffer.col, tokenId);
        require(universalOffer.user != address(0), "Marketplace: offer not found");
        require(block.timestamp < universalOffer.expiry, "Marketplace: offer expired");

        _transferFunds(universalOffer.token, universalOffer.user, msg.sender, universalOffer.amount);
        universalOffer.col.safeTransferFrom(msg.sender, universalOffer.user, tokenId);

        delete _universalOffers[universalOfferId];
        emit UniversalOfferAccepted(universalOfferId, msg.sender, tokenId);
    }

    function _transferFunds(IERC20 token, address from, address to, uint amount) private {
        ERC20Payments.Payee[] memory payees = new ERC20Payments.Payee[](2);
        payees[0] = ERC20Payments.Payee(feeRecipient, miliFee);
        payees[1] = ERC20Payments.Payee(to, 1000 - miliFee);

        if(msg.value > 0) {
            if(address(token) == address(WAVAX)) {
                require(msg.value == amount, "Marketplace: incorrect amount of WAVAX sent");
                (bool succ,) = address(WAVAX).call{value: amount}("");
                require(succ, "Marketplace: WAVAX wrap failed");
                token.split(amount, payees);
            } else revert("Marketplace: AVAX sent for non WAVAX listing.");
        } else {
            token.splitFrom(from, amount, payees);
        }
    }

    function _onlyOwnerOf(IERC721 col, uint tokenId) private view {
        require(col.ownerOf(tokenId) == msg.sender, "Marketplace: not owner of nft");
    }


    function _whitelistToken(IERC20 token) private {
        require(!_allowedTokens[token], "Marketplace: token already whitelisted");
        _allowedTokens[token] = true;
        emit TokenWhitelisted(token);
    }

    modifier onlyWhitelisted(IERC721 col) {
        require(_supportedCollections[col], "Marketplace: collection not supported");
        _;
    }

    modifier onlyWhitelistedToken(IERC20 token) {
        require(_allowedTokens[token], "Marketplace: token not whitelisted");
        _;
    }

    uint private _nonce;
    function _newId() private returns(uint) {
        return _nonce++;
    }


}