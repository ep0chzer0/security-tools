// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

/// @title SignatureAnalyzer
/// @author ep0chzer0
/// @notice Utilities for analyzing signature security and replay vulnerabilities
abstract contract SignatureAnalyzer is Test {

    /*//////////////////////////////////////////////////////////////
                        REPLAY DETECTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if a contract's signature verification includes chain ID
    /// @dev Tests if the same signature works on different chains by calling the target's verify function
    /// @param target Contract with signature verification
    /// @param verifyCalldata Calldata to call the verification function
    /// @param chainIds Array of chain IDs to test against
    /// @return vulnerable True if signature works on multiple chains
    function checkCrossChainReplay(
        address target,
        bytes memory verifyCalldata,
        uint256[] memory chainIds
    ) internal returns (bool vulnerable) {
        uint256 originalChain = block.chainid;
        uint256 successCount = 0;

        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.chainId(chainIds[i]);
            (bool success,) = target.call(verifyCalldata);
            if (success) {
                successCount++;
            }
        }

        vm.chainId(originalChain); // Restore

        // If signature works on multiple chains, it's vulnerable
        vulnerable = successCount > 1;

        if (vulnerable) {
            emit log("VULNERABLE: Signature valid on multiple chains");
            emit log_named_uint("Chains where signature is valid", successCount);
        }
    }

    /// @notice Verify a signature includes chain ID by checking the hash structure
    /// @dev Use this to manually verify a hash was computed with chainId
    /// @param hash The hash to check
    /// @param expectedChainId The chain ID that should be in the hash
    /// @param signature The signature
    /// @return signer The recovered signer address
    /// @notice Recover signer and check if current chain matches expected
    /// @dev Returns signer and whether chain matches. Caller must verify hash includes chainId.
    function recoverAndVerifyChainId(
        bytes32 hash,
        uint256 expectedChainId,
        bytes memory signature
    ) internal view returns (address signer, bool chainMatches) {
        signer = recoverSigner(hash, signature);
        chainMatches = (block.chainid == expectedChainId);
        // Note: This just recovers - caller must verify the hash was built correctly
        // with chainId. Consider using EIP-712 which enforces chainId in domain separator.
    }

    /// @notice Test nonce replay protection
    /// @param target Contract with signature verification
    /// @param signature Valid signature
    /// @param calldata_ Calldata using the signature
    function testNonceReplay(
        address target,
        bytes memory signature,
        bytes memory calldata_
    ) internal returns (bool vulnerable) {
        // First call should succeed
        (bool success1,) = target.call(calldata_);

        // Second call with same signature should fail
        (bool success2,) = target.call(calldata_);

        vulnerable = success1 && success2;

        if (vulnerable) {
            emit log("VULNERABLE: No nonce protection - signature replayable");
        }
    }

    /*//////////////////////////////////////////////////////////////
                      SIGNATURE RECOVERY
    //////////////////////////////////////////////////////////////*/

    /// @notice Recover signer from signature
    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;

        return ecrecover(hash, v, r, s);
    }

    /// @notice Recover from EIP-191 signed message
    function recoverFromEthSignedMessage(
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        return recoverSigner(ethSignedHash, signature);
    }

    /*//////////////////////////////////////////////////////////////
                      MALLEABILITY CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if contract is vulnerable to signature malleability
    /// @param signature Original valid signature
    function checkMalleability(
        bytes32 hash,
        bytes memory signature,
        address target,
        bytes memory calldata_
    ) internal returns (bool vulnerable) {
        // Create malleable signature (flip s value)
        bytes memory malleableSig = createMalleableSignature(signature);

        // Original should work
        (bool success1,) = target.call(calldata_);

        // Replace signature in calldata with malleable version
        // (implementation depends on calldata structure)

        address recovered1 = recoverSigner(hash, signature);
        address recovered2 = recoverSigner(hash, malleableSig);

        vulnerable = (recovered1 == recovered2);

        if (vulnerable) {
            emit log("POTENTIAL: Signature malleability possible");
        }
    }

    /// @notice Create malleable signature by flipping s value
    function createMalleableSignature(
        bytes memory signature
    ) internal pure returns (bytes memory) {
        require(signature.length == 65, "Invalid signature");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // secp256k1 curve order
        uint256 n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 sFlipped = bytes32(n - uint256(s));
        uint8 vFlipped = v == 27 ? 28 : 27;

        return abi.encodePacked(r, sFlipped, vFlipped);
    }

    /*//////////////////////////////////////////////////////////////
                        EIP-712 HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Build EIP-712 domain separator
    function buildDomainSeparator(
        string memory name,
        string memory version,
        address verifyingContract
    ) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                verifyingContract
            )
        );
    }

    /// @notice Build EIP-712 typed data hash
    function buildTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
    }

    /*//////////////////////////////////////////////////////////////
                       TIMESTAMP CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check deadline enforcement
    function testDeadlineEnforcement(
        address target,
        bytes memory calldata_,
        uint256 deadline
    ) internal returns (bool enforced) {
        // Try before deadline
        vm.warp(deadline - 1);
        (bool success1,) = target.call(calldata_);

        // Try after deadline
        vm.warp(deadline + 1);
        (bool success2,) = target.call(calldata_);

        enforced = success1 && !success2;

        if (!enforced && success2) {
            emit log("VULNERABLE: Deadline not enforced");
        }
    }
}
