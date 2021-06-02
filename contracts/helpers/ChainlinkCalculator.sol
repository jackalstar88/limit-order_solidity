// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/AggregatorV3Interface.sol";

/// @title A helper contract for interactions with https://docs.chain.link
contract ChainlinkCalculator {
    uint256 private constant _SPREAD_DENOMINATOR = 1e9;
    uint256 private constant _ORACLE_EXPIRATION_TIME = 30 minutes;
    uint256 private constant _INVERSE_MASK = 1 << 255;

    /// @notice Calculates price of token relative to ETH
    /// @param inverseAndSpread Bitmask for inverse flag and spread. Lowest 254 bits specify spread amount, the highest one specifies if it's an inverse trade
    /// @return Token price times amount
    function singlePrice(AggregatorV3Interface oracle, uint256 inverseAndSpread, uint256 amount) external view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(oracle.latestTimestamp() + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data");
        bool inverse = inverseAndSpread & _INVERSE_MASK > 0;
        uint256 spread = inverseAndSpread & (~_INVERSE_MASK);
        if (inverse) {
            return amount * spread * 1e18 / uint256(oracle.latestAnswer()) / _SPREAD_DENOMINATOR;
        } else {
            return amount * spread * uint256(oracle.latestAnswer()) / 1e18 / _SPREAD_DENOMINATOR;
        }
    }

    /// @notice Calculates price of token A relative to token B. Note that order is important
    /// @param inverseAndSpread Bitmask for inverse flag and spread. Lowest 254 bits specify spread amount, the highest one specifies if it's an inverse trade
    /// @return Token A relative price times amount
    function doublePrice(AggregatorV3Interface oracle1, AggregatorV3Interface oracle2, uint256 spread, uint256 amount) external view returns(uint256) {
        // solhint-disable-next-line not-rely-on-time
        require(oracle1.latestTimestamp() + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data O1");
        // solhint-disable-next-line not-rely-on-time
        require(oracle2.latestTimestamp() + _ORACLE_EXPIRATION_TIME > block.timestamp, "CC: stale data O2");

        return amount * spread * uint256(oracle1.latestAnswer()) / uint256(oracle2.latestAnswer()) / _SPREAD_DENOMINATOR;
    }
}
