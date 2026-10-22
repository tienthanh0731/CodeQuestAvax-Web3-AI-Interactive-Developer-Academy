// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICodeQuestSBT {
    function mintCertificate(
        address student,
        uint256 questId,
        string calldata courseTitle,
        uint256 score
    ) external returns (uint256);
}

/**
 * @title StakeToLearn
 * @notice Commit-to-learn mechanism on Avalanche Fuji C-Chain.
 * @dev Students stake AVAX to commit; successful completion refunds 100% + bonus; forfeits fund the scholarship pool.
 */
contract StakeToLearn {
    address public immutable owner;
    address public verifier;
    ICodeQuestSBT public sbtContract;

    uint256 public constant STAKE_AMOUNT = 0.05 ether; // 0.05 AVAX commitment
    uint256 public constant BONUS_AMOUNT = 0.01 ether; // 0.01 AVAX for top scorers (>= 90)
    uint256 public constant COMMITMENT_PERIOD = 3 days;

    uint256 public scholarshipPool;
    uint256 public totalStudentsStaked;
    uint256 public totalGraduates;

    struct Commitment {
        uint256 questId;
        uint256 stakedAt;
        uint256 deadline;
        bool isStaked;
        bool isCompleted;
        bool isClaimed;
        uint256 score;
    }

    // student => questId => Commitment
    mapping(address => mapping(uint256 => Commitment)) public commitments;

    event Staked(address indexed student, uint256 indexed questId, uint256 deadline, uint256 amount);
    event QuestCompleted(address indexed student, uint256 indexed questId, uint256 score, uint256 refundAmount, uint256 bonusAmount);
    event StakeForfeited(address indexed student, uint256 indexed questId, uint256 forfeitedAmount);
    event ScholarshipFunded(address indexed donor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyVerifierOrOwner() {
        require(msg.sender == verifier || msg.sender == owner, "Unauthorized verifier");
        _;
    }

    constructor(address _sbtAddress, address _verifier) {
        owner = msg.sender;
        verifier = _verifier == address(0) ? msg.sender : _verifier;
        sbtContract = ICodeQuestSBT(_sbtAddress);
    }

    function setSBTContract(address _sbtAddress) external onlyOwner {
        sbtContract = ICodeQuestSBT(_sbtAddress);
    }

    function setVerifier(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    /**
     * @notice Student stakes 0.05 AVAX to start a Quest
     */
    function stakeToJoin(uint256 questId) external payable {
        require(msg.value == STAKE_AMOUNT, "Must stake exactly 0.05 AVAX");
        Commitment storage c = commitments[msg.sender][questId];
        require(!c.isStaked || c.isCompleted, "Already committed to this quest");

        uint256 deadline = block.timestamp + COMMITMENT_PERIOD;
        commitments[msg.sender][questId] = Commitment({
            questId: questId,
            stakedAt: block.timestamp,
            deadline: deadline,
            isStaked: true,
            isCompleted: false,
            isClaimed: false,
            score: 0
        });

        totalStudentsStaked += 1;
        emit Staked(msg.sender, questId, deadline, msg.value);
    }

    /**
     * @notice Called after AI Gemini Auto-Grader verifies student code (score >= 80)
     * @dev Refunds 100% stake + bonus reward + mints Soulbound Certificate
     */
    function graduateQuest(
        address student,
        uint256 questId,
        string calldata courseTitle,
        uint256 score
    ) external onlyVerifierOrOwner {
        Commitment storage c = commitments[student][questId];
        require(c.isStaked, "Student has not staked for this quest");
        require(!c.isCompleted, "Already graduated");
        require(score >= 80, "Minimum score required is 80");
        require(block.timestamp <= c.deadline, "Deadline has passed");

        c.isCompleted = true;
        c.isClaimed = true;
        c.score = score;
        totalGraduates += 1;

        uint256 refundAmount = STAKE_AMOUNT;
        uint256 bonus = 0;

        // Top performers with score >= 90 receive scholarship bonus if pool allows
        if (score >= 90 && scholarshipPool >= BONUS_AMOUNT) {
            bonus = BONUS_AMOUNT;
            scholarshipPool -= BONUS_AMOUNT;
        }

        // Mint Soulbound Token Certificate
        if (address(sbtContract) != address(0)) {
            sbtContract.mintCertificate(student, questId, courseTitle, score);
        }

        // Refund stake + bonus
        (bool success, ) = student.call{value: refundAmount + bonus}("");
        require(success, "Transfer refund failed");

        emit QuestCompleted(student, questId, score, refundAmount, bonus);
    }

    /**
     * @notice Forfeits stake if student dropped out past deadline
     * @dev Forfeited funds replenish the scholarship pool
     */
    function forfeitStake(address student, uint256 questId) external {
        Commitment storage c = commitments[student][questId];
        require(c.isStaked, "No active stake");
        require(!c.isCompleted, "Quest already completed");
        require(block.timestamp > c.deadline, "Deadline not reached yet");

        c.isStaked = false;
        c.isClaimed = true;
        scholarshipPool += STAKE_AMOUNT;

        emit StakeForfeited(student, questId, STAKE_AMOUNT);
    }

    /**
     * @notice Donate to scholarship reward pool
     */
    function depositScholarshipPool() external payable {
        require(msg.value > 0, "No funds provided");
        scholarshipPool += msg.value;
        emit ScholarshipFunded(msg.sender, msg.value);
    }

    function getCommitment(address student, uint256 questId) external view returns (Commitment memory) {
        return commitments[student][questId];
    }

    receive() external payable {
        scholarshipPool += msg.value;
    }
}
