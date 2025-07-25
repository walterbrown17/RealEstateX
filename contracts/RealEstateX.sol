// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _nextId;

    struct Property {
        string location;
        uint256 area;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ========== Storage ==========

    mapping(uint256 => Property) private _properties;                  // propertyId => Property data
    mapping(uint256 => uint256) private _totalShares;                 // propertyId => total share units
    mapping(uint256 => EnumerableSet.AddressSet) private _shareholders; // propertyId => shareholders
    mapping(uint256 => mapping(address => uint256)) private _shares;    // propertyId => (owner => units)

    // ========== Events ==========

    event PropertyMinted(uint256 indexed propertyId, address indexed creator);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 amount);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    constructor() ERC721("RealEstateX", "REX") {}

    // ========== External Functions ==========

    function mintProperty(
        string calldata location,
        uint256 area,
        uint256 valuation,
        string calldata coordinates,
        string calldata description,
        uint256 shareUnits
    ) external {
        uint256 propertyId = _nextId.current();
        _nextId.increment();

        _safeMint(msg.sender, propertyId);

        _properties[propertyId] = Property({
            location: location,
            area: area,
            valuation: valuation,
            coordinates: coordinates,
            description: description
        });

        _totalShares[propertyId] = shareUnits;
        _shareholders[propertyId].add(msg.sender);
        _shares[propertyId][msg.sender] = shareUnits;

        emit PropertyMinted(propertyId, msg.sender);
    }

    function transferShares(
        uint256 propertyId,
        address to,
        uint256 amount
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Not property owner");
        require(_shares[propertyId][msg.sender] >= amount, "Not enough shares");

        _shares[propertyId][msg.sender] -= amount;
        _shares[propertyId][to] += amount;
        _shareholders[propertyId].add(to);

        // Transfer NFT ownership if recipient had no token previously
        if (balanceOf(to) == 0) {
            _transfer(msg.sender, to, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, to, amount);
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
        return _shareholders[propertyId].values();
    }

    function getShareBalance(uint256 propertyId, address holder) external view returns (uint256) {
        return _shares[propertyId][holder];
    }

    function getTotalShares(uint256 propertyId) external view returns (uint256) {
        return _totalShares[propertyId];
    }

    // ========== Overrides ==========

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
