// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private tokenIdCounter;

    struct Property {
        string location;
        uint256 area;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ======== State Variables ========

    mapping(uint256 => Property) private propertyDetails;
    mapping(uint256 => uint256) private totalUnits;
    mapping(uint256 => EnumerableSet.AddressSet) private shareholders;
    mapping(uint256 => mapping(address => uint256)) private shareholdings;

    // ======== Events ========

    event PropertyMinted(uint256 indexed propertyId, address indexed minter);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 units);
    event ValuationChanged(uint256 indexed propertyId, uint256 newValuation);

    // ======== Constructor ========

    constructor() ERC721("RealEstateX", "REX") Ownable(msg.sender) {}

    // ======== Core Functions ========

    function mintProperty(
        string calldata location_,
        uint256 area_,
        uint256 valuation_,
        string calldata coordinates_,
        string calldata description_,
        uint256 units_
    ) external {
        uint256 propertyId = tokenIdCounter.current();
        tokenIdCounter.increment();

        _safeMint(msg.sender, propertyId);

        propertyDetails[propertyId] = Property({
            location: location_,
            area: area_,
            valuation: valuation_,
            coordinates: coordinates_,
            description: description_
        });

        totalUnits[propertyId] = units_;
        shareholders[propertyId].add(msg.sender);
        shareholdings[propertyId][msg.sender] = units_;

        emit PropertyMinted(propertyId, msg.sender);
    }

    function transferShares(
        uint256 propertyId,
        address recipient,
        uint256 units
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Caller is not NFT owner");
        require(shareholdings[propertyId][msg.sender] >= units, "Not enough shares");

        shareholdings[propertyId][msg.sender] -= units;
        shareholdings[propertyId][recipient] += units;
        shareholders[propertyId].add(recipient);

        if (balanceOf(recipient) == 0) {
            _transfer(msg.sender, recipient, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, recipient, units);
    }

    function updateValuation(uint256 propertyId, uint256 updatedValuation) external onlyOwner {
        propertyDetails[propertyId].valuation = updatedValuation;
        emit ValuationChanged(propertyId, updatedValuation);
    }

    // ======== View Functions ========

    function getPropertyInfo(uint256 propertyId) external view returns (Property memory) {
        return propertyDetails[propertyId];
    }

    function getOwners(uint256 propertyId) external view returns (address[] memory) {
        return shareholders[propertyId].values();
    }

    function getShares(uint256 propertyId, address holder) external view returns (uint256) {
        return shareholdings[propertyId][holder];
    }

    // ======== Overrides ========

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
