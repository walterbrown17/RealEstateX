// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _propertyCounter;

    struct Property {
        string location;
        uint256 area;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ========== Storage ==========
    mapping(uint256 => Property) private _properties;
    mapping(uint256 => uint256) private _totalShares;
    mapping(uint256 => EnumerableSet.AddressSet) private _shareholders;
    mapping(uint256 => mapping(address => uint256)) private _shares;

    // ========== Events ==========
    event PropertyMinted(uint256 indexed propertyId, address indexed creator);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 amount);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    // ========== Constructor ==========
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
        uint256 propertyId = _nextPropertyId();

        _safeMint(msg.sender, propertyId);
        _properties[propertyId] = Property(location, area, valuation, coordinates, description);

        _totalShares[propertyId] = shareUnits;
        _addShareholder(propertyId, msg.sender, shareUnits);

        emit PropertyMinted(propertyId, msg.sender);
    }

    function transferShares(
        uint256 propertyId,
        address to,
        uint256 amount
    ) external {
        _validateTransfer(propertyId, to, amount);

        _shares[propertyId][msg.sender] -= amount;
        _shares[propertyId][to] += amount;
        _shareholders[propertyId].add(to);

        if (_shares[propertyId][msg.sender] == 0) {
            _transfer(msg.sender, to, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, to, amount);
    }

    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        require(_exists(propertyId), "Invalid property ID");
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

    function getShareBalance(uint256 propertyId, address account) external view returns (uint256) {
        return _shares[propertyId][account];
    }

    function getTotalShares(uint256 propertyId) external view returns (uint256) {
        return _totalShares[propertyId];
    }

    // ========== Internal Helpers ==========
    function _nextPropertyId() internal returns (uint256) {
        uint256 id = _propertyCounter.current();
        _propertyCounter.increment();
        return id;
    }

    function _addShareholder(uint256 propertyId, address account, uint256 shares) internal {
        _shareholders[propertyId].add(account);
        _shares[propertyId][account] = shares;
    }

    function _validateTransfer(uint256 propertyId, address to, uint256 amount) internal view {
        require(_exists(propertyId), "Property does not exist");
        require(ownerOf(propertyId) == msg.sender, "Caller is not the owner");
        require(_shares[propertyId][msg.sender] >= amount, "Insufficient shares");
        require(to != address(0), "Invalid recipient");
    }

    // ========== Overrides ==========
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
