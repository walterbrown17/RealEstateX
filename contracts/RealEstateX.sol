// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Property {
        string physicalAddress;
        uint256 squareFootage;
        uint256 valuation;
        string geoCoordinates;
        string legalDescription;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => uint256) public propertyShares;
    mapping(uint256 => address[]) public propertyOwners;
    mapping(uint256 => mapping(address => uint256)) public ownershipPercentage;

    event PropertyTokenized(uint256 indexed tokenId, address indexed owner);
    event OwnershipTransferred(uint256 indexed tokenId, address from, address to, uint256 shares);
    event PropertyValuationUpdated(uint256 indexed tokenId, uint256 newValuation);

    constructor() ERC721("RealEstateX", "REX") Ownable(msg.sender) {}

    function tokenizeProperty(
        string memory _physicalAddress,
        uint256 _squareFootage,
        uint256 _valuation,
        string memory _geoCoordinates,
        string memory _legalDescription,
        uint256 _totalShares
    ) external {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(msg.sender, tokenId);
        properties[tokenId] = Property({
            physicalAddress: _physicalAddress,
            squareFootage: _squareFootage,
            valuation: _valuation,
            geoCoordinates: _geoCoordinates,
            legalDescription: _legalDescription
        });

        propertyShares[tokenId] = _totalShares;
        propertyOwners[tokenId].push(msg.sender);
        ownershipPercentage[tokenId][msg.sender] = _totalShares;

        emit PropertyTokenized(tokenId, msg.sender);
    }

    function transferOwnershipShares(
        uint256 _tokenId,
        address _to,
        uint256 _shares
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Not property owner");
        require(ownershipPercentage[_tokenId][msg.sender] >= _shares, "Insufficient shares");

        ownershipPercentage[_tokenId][msg.sender] -= _shares;
        ownershipPercentage[_tokenId][_to] += _shares;

        if (balanceOf(_to) == 0) {
            _transfer(msg.sender, _to, _tokenId);
        }

        emit OwnershipTransferred(_tokenId, msg.sender, _to, _shares);
    }

    function updateValuation(uint256 _tokenId, uint256 _newValuation) external onlyOwner {
        properties[_tokenId].valuation = _newValuation;
        emit PropertyValuationUpdated(_tokenId, _newValuation);
    }

    function getPropertyOwners(uint256 _tokenId) external view returns (address[] memory) {
        return propertyOwners[_tokenId];
    }

    function getOwnerPercentage(uint256 _tokenId, address _owner) external view returns (uint256) {
        return ownershipPercentage[_tokenId][_owner];
    }

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
