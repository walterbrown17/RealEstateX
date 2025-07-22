// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Counter for assigning unique property IDs
    Counters.Counter private _propertyIdTracker;

    // Structure representing a property
    struct Property {
        string location;
        uint256 area;         // in square feet
        uint256 valuation;    // in wei or chosen currency unit
        string coordinates;   // GPS or mapping coordinates
        string description;
    }

    // ======== State Variables ========

    mapping(uint256 => Property) private _properties;
    mapping(uint256 => uint256) private _totalShares;
    mapping(uint256 => EnumerableSet.AddressSet) private _propertyShareholders;
    mapping(uint256 => mapping(address => uint256)) private _holderShares;

    // ======== Events ========

    event PropertyMinted(uint256 indexed propertyId, address indexed creator);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 amount);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    // ======== Constructor ========

    constructor() ERC721("RealEstateX", "REX") Ownable(msg.sender) {}

    // ======== External Functions ========

    /**
     * @notice Mints a new property NFT with associated share ownership.
     */
    function mintProperty(
        string calldata location_,
        uint256 area_,
        uint256 valuation_,
        string calldata coordinates_,
        string calldata description_,
        uint256 shareUnits_
    ) external {
        uint256 newPropertyId = _propertyIdTracker.current();
        _propertyIdTracker.increment();

        _safeMint(msg.sender, newPropertyId);

        _properties[newPropertyId] = Property({
            location: location_,
            area: area_,
            valuation: valuation_,
            coordinates: coordinates_,
            description: description_
        });

        _totalShares[newPropertyId] = shareUnits_;
        _propertyShareholders[newPropertyId].add(msg.sender);
        _holderShares[newPropertyId][msg.sender] = shareUnits_;

        emit PropertyMinted(newPropertyId, msg.sender);
    }

    /**
     * @notice Transfers fractional shares of a property to another user.
     */
    function transferShares(
        uint256 propertyId,
        address recipient,
        uint256 shareAmount
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Caller is not the NFT owner");
        require(_holderShares[propertyId][msg.sender] >= shareAmount, "Insufficient share balance");

        _holderShares[propertyId][msg.sender] -= shareAmount;
        _holderShares[propertyId][recipient] += shareAmount;
        _propertyShareholders[propertyId].add(recipient);

        // Transfer the NFT only if the recipient doesn't already own it
        if (balanceOf(recipient) == 0) {
            _transfer(msg.sender, recipient, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, recipient, shareAmount);
    }

    /**
     * @notice Allows contract owner to update property valuation.
     */
    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        _properties[propertyId].valuation = newValuation;
        emit ValuationUpdated(propertyId, newValuation);
    }

    // ======== View Functions ========

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

    // ======== Internal Overrides ========

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
