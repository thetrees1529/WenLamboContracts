// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Bridge is AccessControl {

    using Counters for Counters.Counter;

    event RequestMade(bytes32 id, Bridging bridging);
    event BridgeFulfilled(bytes32 externalId);

    struct BridgeInfo {
        bool exists;
        Bridging bridging;
    }

    struct Bridging {
        Nft nft;
        Destination dest;
    }

    struct Nft {
        IERC721 imp;
        uint tokenId;
    }

    struct Destination {
        string chain;
        address receiver;
    }


    bytes32 public ESCROW_ROLE = keccak256("ESCROW_ROLE");

    string public chain;
    uint public fee;

    Counters.Counter private _nextRequestNonce;

    mapping(address => bytes32[]) public personalHistory;
    mapping(IERC721 => mapping(uint => bytes32[])) public nftHistory;
    bytes32[] public history;
    mapping(bytes32 => BridgeInfo) private _bridgings;
    mapping(bytes32 => bool) public externalCompletions;

    constructor(string memory chain_) {
        chain = chain_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function personalHistoryLength(address addr) external view returns(uint) {return personalHistory[addr].length;}
    function nftHistoryLength(Nft calldata nft) external view returns(uint) {return _historyOfNft(nft).length;}
    function historyLength() external view returns(uint) {return history.length;}
    function getBridging(bytes32 id) external view returns(Bridging memory) {
        BridgeInfo storage bridgeInfo = _bridgings[id];
        require(bridgeInfo.exists, "Does not exist.");
        return bridgeInfo.bridging;
    }

    function queue(Bridging calldata bridging) external payable {
        require(msg.value == fee);
        Nft calldata nft = bridging.nft;
        nft.imp.transferFrom(msg.sender, address(this), nft.tokenId);
        bytes32 id = _getNewId();

        _bridgings[id] = BridgeInfo({
            exists: true,
            bridging: bridging
        });

        personalHistory[msg.sender].push(id);
        _historyOfNft(nft).push(id);
        history.push(id);

        emit RequestMade(id, bridging);
    }

    function release(bytes32 externalId, Nft calldata nft, address to) external onlyRole(ESCROW_ROLE) {
        require(!externalCompletions[externalId], "Already fulfilled.");
        nft.imp.transferFrom(address(this), to, nft.tokenId);
        externalCompletions[externalId] = true;
        emit BridgeFulfilled(externalId);
    }

    function setFee(uint fee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fee = fee_;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool succ,) = msg.sender.call{value: address(this).balance}("");
        require(succ);
    }

    function _getNewId() private returns(bytes32 id) {
        uint nonce = _nextRequestNonce.current();
        _nextRequestNonce.increment();
        return sha256(abi.encode(chain, nonce));
    }

    function _historyOfNft(Nft memory nft) private view returns(bytes32[] storage) {return nftHistory[nft.imp][nft.tokenId];}

}

