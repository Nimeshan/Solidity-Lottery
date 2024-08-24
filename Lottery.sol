// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function participate() public payable {
        require(msg.value == 1 ether, "Please pay exactly 1 ether");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager, "Unauthorized Access");
        return address(this).balance;
    }

    function random() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager, "You aren't the manager");
        require(players.length >=3, "Insufficient Player");
    
        uint totalPlayers = players.length;
        uint managerShare;
        uint winnersShare;
        uint participantShare;

        if(totalPlayers > 10) {
            managerShare = (address(this).balance * 70) / 100;
            winnersShare = (address(this).balance * 25) / 100;
            participantShare = (address(this).balance * 5) / 100;
        } else {
            managerShare = address(this).balance / 25;
            winnersShare = address(this).balance - managerShare;
            participantShare = 0;
        }
        
        uint numWinners;
        address payable[] memory selectedWinners;

        if(totalPlayers > 10) {
            uint numTopWinners = 2;
            uint remainingWinners = totalPlayers - numTopWinners;
            
            selectedWinners = selectWinners(numTopWinners);
            uint topWinnersShare = winnersShare * 8 / 100;
            distributePrizes(selectedWinners, topWinnersShare, numTopWinners);

            selectedWinners = selectWinners(remainingWinners);
            uint restWinnersShare = winnersShare * 17 / 100;
            distributePrizes(selectedWinners, restWinnersShare, remainingWinners);
            distributeParticipantShare(participantShare);

        } else {
            numWinners = calculateNumberOfWinners(totalPlayers);
            require(numWinners <= totalPlayers, "More winners than players");

            selectedWinners = selectWinners(numWinners);
            distributePrizes(selectedWinners, winnersShare, numWinners);
        }

                payable(manager).transfer(managerShare);
                delete players;
    }

        function calculateNumberOfWinners(uint totalPlayers) internal pure returns(uint) {
            if(totalPlayers == 3){
                return 1;
            } else if (totalPlayers == 6) {
                return 2;
            } else {
                uint extraPlayers = totalPlayers - 6;
                uint additionalWinners = (extraPlayers / 5) * 3;
                return 2 + additionalWinners;
            }
        }

        function selectWinners(uint numWinners) internal returns(address payable[] memory) {
            address payable[] memory selectedWinners = new address payable[](numWinners);
            for(uint i = 0; i < numWinners; i++){
                uint r = random();
                uint index = r % players.length;
                selectedWinners[i] = players[index];

                players[index] = players[players.length - 1];
                players.pop();
            }
            return selectedWinners;
        }

        function distributePrizes(address payable[] memory winners, uint winnersShare, uint numWinners) internal {
            uint prizePerWinner = winnersShare / numWinners;
            for (uint i = 0; i < winners.length; i++) {
                winners[i].transfer(prizePerWinner);
            }
        }

        function distributeParticipantShare(uint participantsShare) internal {
            uint numParticipants = players.length;
            uint sharePerParticipant = participantsShare / numParticipants;
            for (uint i = 0; i < numParticipants; i++) {
                players[i].transfer(sharePerParticipant);
            }
        }
}