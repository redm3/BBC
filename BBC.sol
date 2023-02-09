// SPDX-License-Identifier: MIT

//.==-.                   .-==.
// \()8`-._  `.   .'  _.-'8()/
// (88"   ::.  \./  .::   "88)
//  \_.'`-::::.(#).::::-'`._/
//    `._... .q(_)p. ..._.'
//      ""-..-'|B|`-..-""
//      .""' .'|B|`. `"".
//    ,':8(o)./|C|\.(o)8:`.
//   (O :8 ::/ \_/ \:: 8: O)
//    \O `::/       \::' O/
//     ""--'         `--""   
//0x4Bc4bbA990Fe31D529D987f7b8CcF79F1626e559 BTRFLY
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BBC is ERC721A, Ownable{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 200;
    uint256 public constant MAX_WHITELIST_MINT = 300;
    uint256 public constant PUBLIC_BTRFLY_SALE_PRICE = 1 ether;
    uint256 public constant WHITELIST_BTRFLY_SALE_PRICE = 1 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    bool public teamMinted;

    address Btrfly;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor(address btrfly) ERC721A("BBC", "BabyButterflyCartel"){
        Btrfly = btrfly;

    }
    //stops botting from contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "BBC :: Cannot be called by a contract");
        _;
    }

    //Public mints
    function mintWithBtrfly(uint256 _quantity, uint256 _costBtrfly) external callerIsUser{
        require(publicSale, "BBC :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "BBC :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "BBC :: Already minted 200 times!");
        require(_costBtrfly == (PUBLIC_BTRFLY_SALE_PRICE  * _quantity), "BBC :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        IERC20(Btrfly).safeTransferFrom(msg.sender, address(this), _costBtrfly);
        _safeMint(msg.sender, _quantity);
    }

    function whitelistmintWithBtrfly(bytes32[] memory _merkleProof, uint256 _quantity, uint256 _costBtrfly) external callerIsUser{
        require(whiteListSale, "BBC :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "BBC :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "BBC :: Cannot mint beyond whitelist max mint!");
        require(_costBtrfly  == (WHITELIST_BTRFLY_SALE_PRICE * _quantity), "BBC :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "BBC :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        IERC20(Btrfly).safeTransferFrom(msg.sender, address(this), _costBtrfly);
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "BBC :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 20);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function collectBtrfly() public onlyOwner{
        uint256 bal = IERC20(Btrfly).balanceOf(address(this));
        IERC20(Btrfly).safeTransfer(owner(), bal);
    }
}
