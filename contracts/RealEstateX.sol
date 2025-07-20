// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIdTracker;

    struct Property {
        string physicalAddress;
        uint256 squareFootage;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ========== Storage ==========

    mapping(uint256 => Property) private _properties;
    mapping(uint256 => uint256) private _totalShares;
    mapping(uint256 => EnumerableSet.AddressSet) private _propertyOwners;
    mapping(uint256 => mapping(address => uint256)) private _ownerShares;

    // ========== Events ==========

    event PropertyMinted(uint256 indexed propertyId, address indexed owner);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 shares);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    // ========== Constructor ==========

    constructor() ERC721("RealEstateX", "REX") Ownable(msg.sender) {}

    // ========== Core Functions ==========

    function mintProperty(
        string calldata physicalAddress_,
        uint256 squareFootage_,
        uint256 valuation_,
        string calldata coordinates_,
        string calldata description_,
        uint256 totalUnits_
    ) external {
        uint256 newPropertyId = _tokenIdTracker.current();
        _tokenIdTracker.increment();

        _safeMint(msg.sender, newPropertyId);

        _properties[newPropertyId] = Property({
            physicalAddress: physicalAddress_,
            squareFootage: squareFootage_,
            valuation: valuation_,
            coordinates: coordinates_,
            description: description_
        });

        _totalShares[newPropertyId] = totalUnits_;
        _propertyOwners[newPropertyId].add(msg.sender);
        _ownerShares[newPropertyId][msg.sender] = totalUnits_;

        emit PropertyMinted(newPropertyId, msg.sender);
    }

    function transferShares(
        uint256 propertyId,
        address to,
        uint256 shares
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Not the NFT owner");
        require(_ownerShares[propertyId][msg.sender] >= shares, "Insufficient shares");

        _ownerShares[propertyId][msg.sender] -= shares;
        _ownerShares[propertyId][to] += shares;
        _propertyOwners[propertyId].add(to);

        if (balanceOf(to) == 0) {
            _transfer(msg.sender, to, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, to, shares);
    }

    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        _properties[propertyId].valuation = newValuation;
        emit ValuationUpdated(propertyId, newValuation);
    }

    // ========== View Functions ==========

    function getPropertyInfo(uint256 propertyId) external view returns (Property memory) {
        return _properties[propertyId];
    }

    function getOwners(uint256 propertyId) external view returns (address[] memory) {
        return _propertyOwners[propertyId].values();
    }

    function getShares(uint256 propertyId, address owner) external view returns (uint256) {
        return _ownerShares[propertyId][owner];
    }

    // ========== Overrides ==========

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
