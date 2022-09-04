// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


interface IERC721 is IERC165{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract RadicalNFT is IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IERC20 private _coin;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Tax rate. 1000 = 100 %
    uint private _rate;

    // Duaration of one cycle
    uint private _cycleDuration;

    uint private _mintPrice;

    uint private _maxItemNum;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    struct tax {
        uint256 amount;
        uint256 timelimit;
    }

    mapping(uint256 => tax) private _taxes;

    struct priceAtTime {
        uint256 price;
        uint256 timestamp;
    }

    mapping(uint256 => priceAtTime[]) private _priceHistorys;

    constructor(
        string memory name_, 
        string memory symbol_, 
        address coinAddress_, 
        uint cycleDuration_, 
        uint rate_, 
        uint mintPrice_, 
        uint maxItemNum_
        ) {
        _name = name_;
        _symbol = symbol_;
        _coin = IERC20(coinAddress_);
        _cycleDuration = cycleDuration_;
        _rate = rate_;
        _mintPrice = mintPrice_;
        _maxItemNum = maxItemNum_;
    }

    function mint() public returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        uint currentTime = block.timestamp;
        require(newItemId < _maxItemNum, "maxItemNum reached");
        require(_coin.allowance(msg.sender, address(this)) >= _mintPrice);
        require(_coin.transferFrom(msg.sender, address(this), _mintPrice));
        _mint(msg.sender, newItemId);
        _taxes[newItemId] = tax(_mintPrice*_rate/1000, currentTime + _cycleDuration);
        _tokenIds.increment();
        return newItemId;
    }

    function confiscation(uint256 tokenId) public returns (bool) {
        uint amount = _taxes[tokenId].amount;
        uint timelimit = _taxes[tokenId].timelimit;
        uint currentTime = block.timestamp;
        if (amount != 0){
            if (currentTime > timelimit) {
                _burn(tokenId);
                return true;
            }
        } else {
            if (currentTime > timelimit + _cycleDuration) {
                _burn(tokenId);
                return true;
            }
        }
        return false;
    }

    function update(uint256 tokenId) public {
        uint currentTime = block.timestamp;
        uint timelimit = _taxes[tokenId].timelimit;
        require(currentTime > timelimit && currentTime <= timelimit + _cycleDuration, "upadate condition unsatisfied");
        uint avgPrice = getAvgPrice(tokenId, timelimit - _cycleDuration, timelimit);
        uint taxAmount = avgPrice*_rate/1000;
        _taxes[tokenId] = tax(taxAmount, timelimit + _cycleDuration);
    }

    function payTax(uint256 tokenId) public {
        uint currentTime = block.timestamp;
        uint amount = _taxes[tokenId].amount;
        uint timelimit = _taxes[tokenId].timelimit;
        require(currentTime <= timelimit);
        require(_coin.allowance(msg.sender, address(this)) >= amount);
        require(_coin.transferFrom(msg.sender, address(this), amount));
        _taxes[tokenId] = tax(0, timelimit + _cycleDuration);
    }

    function buy(uint256 tokenId) public {
        require(!confiscation(tokenId), "consficated");
        address owner = RadicalNFT.ownerOf(tokenId);
        require(owner != msg.sender, "you already own this NFT");
        priceAtTime[] memory priceHistory = _priceHistorys[tokenId];
        uint price = priceHistory[priceHistory.length - 1].price;
        uint taxBefore = _taxes[tokenId].amount;
        uint timelimit = _taxes[tokenId].timelimit;
        uint currentTime = block.timestamp;
        uint duration = currentTime - timelimit;
        uint taxNow = getAvgPrice(tokenId, timelimit, currentTime)*_rate*duration/(1000*_cycleDuration);
        uint totalAmount = price + taxBefore + taxNow;
        require(_coin.allowance(msg.sender, address(this)) >= totalAmount);
        require(_coin.transferFrom(msg.sender, address(this), totalAmount));
        _transfer(owner, msg.sender, tokenId);
        _taxes[tokenId] = tax(0, currentTime + _cycleDuration);
    }

    function setPrice(uint256 price, uint256 tokenId) public {
        require(RadicalNFT.ownerOf(tokenId) == msg.sender, "ERC721: setprice incorrect owner");
        _priceHistorys[tokenId].push(priceAtTime(price, block.timestamp));
    }

    function getAvgPrice(uint256 tokenId, uint256 start, uint256 end) public view returns (uint256) {
        require(start < end);
        priceAtTime[] memory priceHistory = _priceHistorys[tokenId];
        uint startIndex = 0;
        for(uint i=0; i < priceHistory.length; i++ ){
            if(priceHistory[i].timestamp > start){
                break;
            }
            startIndex = i;
        }
        uint endIndex = 0;
        for(uint i=0; i < priceHistory.length; i++ ){
            if(priceHistory[i].timestamp > end){
                break;
            }
            endIndex = i;
        }
        uint priceCum = 0;
        for(uint i=startIndex; i <= endIndex; i++ ){
            if ( i == startIndex ) {
                priceCum += priceHistory[i].price*(priceHistory[i+1].timestamp - start);
            } else if (i < endIndex) {
                priceCum += priceHistory[i].price*(priceHistory[i+1].timestamp - priceHistory[i].timestamp);
            } else {
                priceCum += priceHistory[i].price*(end - priceHistory[i].timestamp);
            }
        }
        return priceCum/(end - start);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = RadicalNFT.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(RadicalNFT.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

}
