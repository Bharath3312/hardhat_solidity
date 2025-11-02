// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Campaign {
    enum Status {
        Funding,
        askInvestors,       // Campaign running
        CanWithdrawn,  // Owner can withdraw
        Refunded  ,     // Investors refunded
        Completed,     // Campaign completed
        Failed
    }
    enum FundCategories {
        Technology,
        Community,
        Education,
        Environment,
        Health,
        Bussines,
        Others
    }
    enum FundingType {
        AllorNothing, // once campaign full can withdraw
        Flexible // can withdraw whatever amount invested
    }

    enum VStatus {Processing, Won, Loser }

    struct VoteRequest {
        uint256 amount;
        uint8 yesVotes;
        uint8 noVotes;
        VStatus status;
        mapping(address => bool) voters; // can't return this to frontend directly
    }

    struct CampaignData {
        string title;
        string description;
        string imageUrl;
        string pdfUrl;
        uint256 minAmount;
        uint256 maxAmount;
        FundingType fundingType;
        uint256 deadline;
        uint256 graceDays;
        address owner;
        uint256 totalInvested;
        Status status;
        uint8 totalRaisingVotes;
        uint8 totalInvestors;
    }

    CampaignData internal  campaign; // ✅ Single struct to hold all campaign info
    mapping(address => uint256) public investors; // ✅ Investors stored here
    VoteRequest[] public voteRequests;

    event StatusChanged(Status newStatus);
    event Invested(address investor, uint256 amount);
    event Withdrawn(address owner, uint256 amount);
    event Refunded(address investor, uint256 amount);

    constructor(
        string memory _title,
        string memory _description,
        string memory _imgUrl,
        string memory _pdfUrl,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint8 _fundingType,
        uint256 _deadline,
        uint256 _graceDays,
        address _owner
    ) {
        require(_minAmount < _maxAmount, "Min must be < Max");
        require(_deadline > block.timestamp, "Deadline must be in future");
        require(_fundingType <= uint8(FundingType.Flexible), "Invalid funding type");

        campaign.title = _title;
        campaign.description = _description;
        campaign.imageUrl = _imgUrl;
        campaign.pdfUrl = _pdfUrl;
        campaign.minAmount = _minAmount;
        campaign.maxAmount = _maxAmount;
        campaign.fundingType = FundingType(_fundingType);
        campaign.deadline = _deadline;
        campaign.graceDays = _graceDays;
        campaign.owner = _owner;
        campaign.totalInvested = 0;
        campaign.status = Status.Funding;
        campaign.totalInvestors = 0;
        campaign.totalRaisingVotes = 0;


        emit StatusChanged(campaign.status);
    }

   function getCampaginData() public view returns (CampaignData memory) {
        CampaignData memory updated = campaign;

        if (block.timestamp >= updated.deadline) {
            if (updated.fundingType == FundingType.AllorNothing) {
                updated.status = updated.totalInvested >= updated.maxAmount
                    ? Status.askInvestors
                    : Status.Failed;
            } else {
                updated.status = updated.totalInvested >= updated.minAmount
                    ? Status.askInvestors
                    : Status.Failed;
            }
        }

        return updated;
    }
    modifier Helper() {
        if (block.timestamp >= campaign.deadline) {
            if (campaign.fundingType == FundingType.AllorNothing) {
                campaign.status = campaign.totalInvested >= campaign.maxAmount 
                    ? Status.askInvestors 
                    : Status.Failed;
            } else {
                campaign.status = campaign.totalInvested >= campaign.minAmount 
                    ? Status.askInvestors 
                    : Status.Failed;
            }
            emit StatusChanged(campaign.status);
        }
        _; // always continue
    }

    function invest() external Helper payable {
        require(campaign.status == Status.Funding, "Not accepting funds");
        require(msg.value >= campaign.minAmount, "Below min amount");
        require(campaign.totalInvested + msg.value <= campaign.maxAmount, "Exceeds max funding");
        require(msg.sender != campaign.owner || campaign.fundingType ==  FundingType.AllorNothing, "Owner cannot invest");

        campaign.totalInvestors += investors[msg.sender] > 0 ? 0 : 1;
        investors[msg.sender] += msg.value;
        campaign.totalInvested += msg.value;

        emit Invested(msg.sender, msg.value);

        if (campaign.totalInvested >= campaign.maxAmount) {
            campaign.status = Status.askInvestors;
            campaign.deadline = block.timestamp + campaign.graceDays ;
            emit StatusChanged(campaign.status);
        }
    }

    function raiseTovote() external Helper {
        require(msg.sender == campaign.owner, "Only owner");
        require(campaign.status == Status.askInvestors, "Not in funding");
        if(voteRequests.length > 0){
            require(voteRequests[voteRequests.length - 1].status != VStatus.Processing,"Raise Voting to Failed!");
        }
        voteRequests.push();
        VoteRequest storage vr = voteRequests[voteRequests.length - 1];
        vr.amount = campaign.totalInvested;
        vr.yesVotes = 0;
        vr.noVotes = 0;
        vr.status = VStatus.Processing;
        campaign.totalRaisingVotes += 1;
    }

    function vote(uint256 _requestId, bool _support) external {
        require(_requestId < voteRequests.length, "Invalid request");
        require(investors[msg.sender] > 0, "your the Not an investor");
        VoteRequest storage vr = voteRequests[_requestId];
        require(vr.status == VStatus.Processing || vr.yesVotes+vr.noVotes < 100, "Voting is not active");
        require(!vr.voters[msg.sender], "Already voted");

        vr.voters[msg.sender] = true;

        uint8 votePercentage = uint8((investors[msg.sender] * 100) / campaign.totalInvested);

        if (_support) {
            vr.yesVotes += votePercentage;
        } else {
            vr.noVotes += votePercentage;
        }
        if (vr.status == VStatus.Processing){
            if (vr.yesVotes >= 51) {
                vr.status = VStatus.Won;
                campaign.status = Status.CanWithdrawn;
            }
            else if(vr.noVotes >= 50) {
                vr.status = VStatus.Loser;
                if(voteRequests.length ==  3){
                    campaign.status = Status.Refunded;
                }
            }
            emit StatusChanged(campaign.status);
        }

    }

    function withdraw() external {
        require(msg.sender == campaign.owner, "Only owner");
        require(campaign.status == Status.CanWithdrawn, "Withdraw not allowed");
        require(block.timestamp <= campaign.deadline, "Grace period active");

        uint256 amount = campaign.totalInvested;
        campaign.totalInvested = 0;

        (bool success, ) = campaign.owner.call{value: amount}("");
        require(success, "Withdraw failed");
        campaign.status = Status.Completed;
        emit StatusChanged(campaign.status);    
        emit Withdrawn(campaign.owner, amount);
    }

    function refund() external {
        require(campaign.status == Status.Refunded, "Refund not allowed yet");
        // require(block.timestamp > campaign.deadline, "Deadline not passed");

        uint256 invested = investors[msg.sender];
        require(invested > 0, "Nothing to refund");

        (bool success, ) = msg.sender.call{value: invested}("");
        require(success, "Refund failed");
        investors[msg.sender] = 0;
        campaign.totalInvested -= invested;
        if(campaign.totalInvested == 0) {
            campaign.status = Status.Failed;
        }

        emit Refunded(msg.sender, invested);
    }
}
