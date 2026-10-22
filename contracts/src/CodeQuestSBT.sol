// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CodeQuestSBT
 * @notice Soulbound Token (SBT) for CodeQuestAvax graduates.
 * @dev Non-transferable ERC-721 certificate representing verified IT/Web3 skills.
 */
contract CodeQuestSBT {
    string public name = "CodeQuestAvax Verified Developer SBT";
    string public symbol = "CQ-SBT";

    address public immutable owner;
    address public stakeContract;
    uint256 private _nextTokenId;

    struct Certificate {
        uint256 questId;
        string courseTitle;
        uint256 score;
        uint256 timestamp;
        address recipient;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) private _studentTokens;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    event CertificateMinted(
        uint256 indexed tokenId,
        address indexed student,
        uint256 indexed questId,
        string courseTitle,
        uint256 score,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyStakeOrOwner() {
        require(msg.sender == stakeContract || msg.sender == owner, "Unauthorized issuer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setStakeContract(address _stakeContract) external onlyOwner {
        stakeContract = _stakeContract;
    }

    /**
     * @notice Mint a Soulbound Certificate upon passing AI auto-grading
     */
    function mintCertificate(
        address student,
        uint256 questId,
        string calldata courseTitle,
        uint256 score
    ) external onlyStakeOrOwner returns (uint256) {
        require(student != address(0), "Invalid recipient");
        require(score >= 80, "Score below passing threshold (80)");

        uint256 tokenId = ++_nextTokenId;

        _owners[tokenId] = student;
        _balances[student] += 1;
        _studentTokens[student].push(tokenId);

        certificates[tokenId] = Certificate({
            questId: questId,
            courseTitle: courseTitle,
            score: score,
            timestamp: block.timestamp,
            recipient: student
        });

        emit CertificateMinted(tokenId, student, questId, courseTitle, score, block.timestamp);
        return tokenId;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "Token does not exist");
        return tokenOwner;
    }

    function balanceOf(address student) external view returns (uint256) {
        require(student != address(0), "Zero address query");
        return _balances[student];
    }

    function getStudentCertificates(address student) external view returns (uint256[] memory) {
        return _studentTokens[student];
    }

    function getCertificate(uint256 tokenId) external view returns (Certificate memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return certificates[tokenId];
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    // Soulbound enforcement: Transfers are strictly prohibited!
    function transferFrom(address, address, uint256) external pure {
        revert("Soulbound Token: Transfer is disabled");
    }

    function safeTransferFrom(address, address, uint256) external pure {
        revert("Soulbound Token: Transfer is disabled");
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert("Soulbound Token: Transfer is disabled");
    }
}
