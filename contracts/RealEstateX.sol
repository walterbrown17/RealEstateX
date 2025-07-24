// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _propertyIdCounter;

    struct Property {
        string location;
        uint256 area;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // PropertyId => Property metadata
    mapping(uint256 => Property) private _properties;

    // PropertyId => total share units available
    mapping(uint256 => uint256) private _totalShares;

    // PropertyId => set of shareholders
    mapping(uint256 => EnumerableSet.AddressSet) private _propertyShareholders;

    // PropertyId => (holder => share units)
    mapping(uint256 => mapping(address => uint256)) private _holderShares;

    // Events
    event PropertyMinted(uint256 indexed propertyId, address indexed creator);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 amount);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    constructor() ERC721("RealEstateX", "REX") {}

    // ========== External Functions ==========

    function mintProperty(
        string calldata location_,
        uint256 area_,
        uint256 valuation_,
        string calldata coordinates_,
        string calldata description_,
        uint256 shareUnits_
    ) external {
        uint256 propertyId = _propertyIdCounter.current();
        _propertyIdCounter.increment();

        _safeMint(msg.sender, propertyId);

        _properties[propertyId] = Property({
            location: location_,
            area: area_,
            valuation: valuation_,
            coordinates: coordinates_,
            description: description_
        });

        _totalShares[propertyId] = shareUnits_;
        _propertyShareholders[propertyId].add(msg.sender);
        _holderShares[propertyId][msg.sender] = shareUnits_;

        emit PropertyMinted(propertyId, msg.sender);
    }

    function transferShares(
        uint256 propertyId,
        address recipient,
        uint256 shareAmount
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Not NFT owner");
        require(_holderShares[propertyId][msg.sender] >= shareAmount, "Insufficient shares");

        _holderShares[propertyId][msg.sender] -= shareAmount;
        _holderShares[propertyId][recipient] += shareAmount;
        _propertyShareholders[propertyId].add(recipient);

        if (balanceOf(recipient) == 0) {
            _transfer(msg.sender, recipient, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, recipient, shareAmount);
    }

    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        _properties[propertyId].valuation = newValuation;
        emit ValuationUpdated(propertyId, newValuation);
    }

    // ========== View Functions ==========

    function getPropertyInfo(uint256 propertyId) external view returns (Property memory) {
        return _properties[propertyId];
    }

    function getShareholders(uint256 propertyId) external view returns (address[] memory) {
        return _propertyShareholders[propertyId].values();
    }

    function getShareBalance(uint256 propertyId, address holder) external view returns (uint256) {
        return _holderShares[propertyId][holder];
    }

    function getTotalShares(uint256 propertyId) external view returns (uint256) {
        return _totalShares[propertyId];
    }

    // ========== Internal Overrides ==========

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
