// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "./campaign.sol";    
contract CampaignFactory {

    uint256 public graceDays = 3 days;
    Campaign[] public campaigns;
    event CampaignCreated(address campaignAddress, address owner);

    function createCampaign(
        string memory _title,
        string memory _description,
        string memory _imgUrl,
        string memory _pdfUrl,

        uint256 _minAmount,
        uint256 _maxAmount,
        uint8 _fundingType,
        uint256 _deadline   
    ) external returns(address) {
        Campaign newCampaign = new Campaign(_title, _description,_imgUrl, _pdfUrl,_minAmount, _maxAmount, _fundingType, _deadline, graceDays, msg.sender);
        campaigns.push(newCampaign);
        emit CampaignCreated(address(newCampaign), msg.sender);
        return address(newCampaign);
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }
}
