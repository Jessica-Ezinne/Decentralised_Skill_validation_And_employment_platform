import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// User Profile Tests
Clarinet.test({
    name: "Ensure that users can register with valid details",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const deployer = accounts.get("deployer")!;
        const user1 = accounts.get("wallet_1")!;

        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [
                    types.utf8("John Doe"),
                    types.utf8("Experienced developer with 5 years in blockchain")
                ],
                user1.address
            )
        ]);

        // Assert successful registration
        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        assertEquals(block.receipts[0].result, '(ok true)');
    },
});

Clarinet.test({
    name: "Ensure that duplicate user registration fails",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const user1 = accounts.get("wallet_1")!;

        // First registration
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [
                    types.utf8("John Doe"),
                    types.utf8("Bio")
                ],
                user1.address
            )
        ]);

        // Second registration attempt
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [
                    types.utf8("John Doe 2"),
                    types.utf8("Bio 2")
                ],
                user1.address
            )
        ]);

        assertEquals(block.receipts[0].result, `(err u${2})`); // ERR-ALREADY-REGISTERED
    },
});

// Skill Management Tests
Clarinet.test({
    name: "Ensure that registered users can create skills",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const user1 = accounts.get("wallet_1")!;

        // First register the user
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [
                    types.utf8("John Doe"),
                    types.utf8("Bio")
                ],
                user1.address
            )
        ]);

        // Then create a skill
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-skill",
                [
                    types.utf8("Solidity"),
                    types.utf8("Blockchain"),
                    types.utf8("Smart contract development with Solidity"),
                    types.uint(3) // required validations
                ],
                user1.address
            )
        ]);

        assertEquals(block.receipts[0].result, '(ok true)');
    },
});

// Validator Tests
Clarinet.test({
    name: "Ensure that users can register as validators with sufficient reputation",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const user1 = accounts.get("wallet_1")!;

        // Register user
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [
                    types.utf8("John Doe"),
                    types.utf8("Bio")
                ],
                user1.address
            )
        ]);

        // Register as validator
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-validator",
                [
                    types.list([types.uint(1), types.uint(2), types.uint(3)]) // expertise
                ],
                user1.address
            )
        ]);

        assertEquals(block.receipts[0].result, '(ok true)');
    },
});

// Skill Validation Tests
Clarinet.test({
    name: "Ensure that validators can validate skills",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const user1 = accounts.get("wallet_1")!;
        const validator1 = accounts.get("wallet_2")!;

        // Setup: Register user and create skill
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [types.utf8("John"), types.utf8("Bio")],
                user1.address
            ),
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [types.utf8("Val"), types.utf8("Validator Bio")],
                validator1.address
            ),
            Tx.contractCall(
                "skill_validation_employment",
                "register-skill",
                [
                    types.utf8("Solidity"),
                    types.utf8("Blockchain"),
                    types.utf8("Description"),
                    types.uint(3)
                ],
                user1.address
            )
        ]);

        // Register validator
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-validator",
                [types.list([types.uint(1)])],
                validator1.address
            )
        ]);

        // Validate skill
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "validate-skill",
                [
                    types.principal(user1.address),
                    types.uint(1)  // skill-id
                ],
                validator1.address
            )
        ]);

        assertEquals(block.receipts[0].result, '(ok true)');
    },
});

// Employment Record Tests
Clarinet.test({
    name: "Ensure that users can add employment records",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const user1 = accounts.get("wallet_1")!;
        const employer = accounts.get("wallet_2")!;

        // Register user
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [types.utf8("John"), types.utf8("Bio")],
                user1.address
            )
        ]);

        // Add employment record
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "add-employment-record",
                [
                    types.principal(employer.address),
                    types.utf8("Senior Developer"),
                    types.uint(100),  // start date
                    types.uint(200)   // end date
                ],
                user1.address
            )
        ]);

        assertEquals(block.receipts[0].result, '(ok true)');
    },
});

// Contract Management Tests
Clarinet.test({
    name: "Ensure that only contract owner can update platform fee",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const deployer = accounts.get("deployer")!;
        const user1 = accounts.get("wallet_1")!;

        // Try updating fee as non-owner
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "update-platform-fee",
                [types.uint(200)],
                user1.address
            )
        ]);

        assertEquals(block.receipts[0].result, `(err u${1})`); // ERR-NOT-AUTHORIZED

        // Update fee as owner
        block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "update-platform-fee",
                [types.uint(200)],
                deployer.address
            )
        ]);

        assertEquals(block.receipts[0].result, '(ok true)');
    },
});

// Read-only Function Tests
Clarinet.test({
    name: "Ensure that user profiles can be retrieved",
    async fn(chain: Chain, accounts: Map<string, Account>)
    {
        const user1 = accounts.get("wallet_1")!;
        const name = "John Doe";
        const bio = "Experienced developer";

        // Register user
        let block = chain.mineBlock([
            Tx.contractCall(
                "skill_validation_employment",
                "register-user",
                [types.utf8(name), types.utf8(bio)],
                user1.address
            )
        ]);

        // Get user profile
        const profile = chain.callReadOnlyFn(
            "skill_validation_employment",
            "get-user-profile",
            [types.principal(user1.address)],
            user1.address
        );

        // Assert profile exists and has correct data
        assertEquals(profile.result, `(some {bio: "${bio}", is-validator: false, name: "${name}", registration-time: u2, reputation-score: u100, total-validations: u0})`);
    },
});