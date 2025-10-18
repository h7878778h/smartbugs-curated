// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "./ERC20Mock.sol";
import {IERC20} from "../dataset/IERC20.sol";
import {IERC20Metadata} from "../dataset/extensions/IERC20Metadata.sol";
import {IERC20Errors} from "../interfaces/draft-IERC6093.sol";

contract ERC20Test is Test {
    ERC20Mock token;
    
    address owner = address(this);
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    
    string constant TOKEN_NAME = "Test Token";
    string constant TOKEN_SYMBOL = "TEST";
    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function setUp() public {
        token = new ERC20Mock(TOKEN_NAME, TOKEN_SYMBOL);
        token.mint(owner, INITIAL_SUPPLY);
    }
    
    // ============ Constructor Tests ============
    
    function test_Constructor_SetsNameAndSymbol() public view {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
    }
    
    function test_Constructor_SetsDefaultDecimals() public view {
        assertEq(token.decimals(), 18);
    }
    
    function test_Constructor_InitialSupplyIsZero() public {
        ERC20Mock newToken = new ERC20Mock("New Token", "NEW");
        assertEq(newToken.totalSupply(), 0);
    }
    
    function testFuzz_Constructor_ArbitraryNameAndSymbol(string memory name, string memory symbol) public {
        ERC20Mock newToken = new ERC20Mock(name, symbol);
        assertEq(newToken.name(), name);
        assertEq(newToken.symbol(), symbol);
    }
    
    // ============ Metadata Tests ============
    
    function test_Name_ReturnsCorrectName() public view {
        assertEq(token.name(), TOKEN_NAME);
    }
    
    function test_Symbol_ReturnsCorrectSymbol() public view {
        assertEq(token.symbol(), TOKEN_SYMBOL);
    }
    
    function test_Decimals_ReturnsEighteen() public view {
        assertEq(token.decimals(), 18);
    }
    
    // ============ TotalSupply Tests ============
    
    function test_TotalSupply_ReturnsInitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }
    
    function test_TotalSupply_UpdatesAfterMint() public {
        uint256 mintAmount = 1000 * 10**18;
        token.mint(alice, mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }
    
    function test_TotalSupply_UpdatesAfterBurn() public {
        uint256 burnAmount = 1000 * 10**18;
        token.burn(owner, burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }
    
    function testFuzz_TotalSupply_ConsistentAcrossMintAndBurn(uint128 mintAmount, uint128 burnAmount) public {
        vm.assume(burnAmount <= mintAmount);
        
        token.mint(alice, mintAmount);
        uint256 supplyAfterMint = token.totalSupply();
        
        token.burn(alice, burnAmount);
        uint256 supplyAfterBurn = token.totalSupply();
        
        assertEq(supplyAfterBurn, supplyAfterMint - burnAmount);
    }
    
    // ============ BalanceOf Tests ============
    
    function test_BalanceOf_ReturnsCorrectBalance() public view {
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }
    
    function test_BalanceOf_ReturnsZeroForNewAddress() public view {
        assertEq(token.balanceOf(alice), 0);
    }
    
    function test_BalanceOf_UpdatesAfterTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        token.transfer(alice, transferAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }
    
    function testFuzz_BalanceOf_CorrectAfterMint(address account, uint256 amount) public {
        vm.assume(account != address(0));
        vm.assume(amount < type(uint256).max - token.totalSupply());
        
        uint256 initialBalance = token.balanceOf(account);
        token.mint(account, amount);
        
        assertEq(token.balanceOf(account), initialBalance + amount);
    }
    
    // ============ Transfer Tests ============
    
    function test_Transfer_SuccessfulTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        bool success = token.transfer(alice, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }
    
    function test_Transfer_EmitsTransferEvent() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, transferAmount);
        
        token.transfer(alice, transferAmount);
    }
    
    function test_Transfer_RevertsWhenToIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0))
        );
        token.transfer(address(0), 1000);
    }
    
    function test_Transfer_RevertsWhenInsufficientBalance() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                owner,
                INITIAL_SUPPLY,
                INITIAL_SUPPLY + 1
            )
        );
        token.transfer(alice, INITIAL_SUPPLY + 1);
    }
    
    function test_Transfer_AllowsZeroValueTransfer() public {
        bool success = token.transfer(alice, 0);
        assertTrue(success);
        assertEq(token.balanceOf(alice), 0);
    }
    
    function test_Transfer_AllowsTransferEntireBalance() public {
        bool success = token.transfer(alice, INITIAL_SUPPLY);
        
        assertTrue(success);
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY);
    }
    
    function test_Transfer_SelfTransfer() public {
        uint256 amount = 1000 * 10**18;
        bool success = token.transfer(owner, amount);
        
        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }
    
    function testFuzz_Transfer_CorrectBalanceUpdates(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to != owner);
        vm.assume(amount <= INITIAL_SUPPLY);
        
        token.transfer(to, amount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(to), amount);
    }
    
    // ============ Approve Tests ============
    
    function test_Approve_SetsAllowance() public {
        uint256 approvalAmount = 1000 * 10**18;
        bool success = token.approve(alice, approvalAmount);
        
        assertTrue(success);
        assertEq(token.allowance(owner, alice), approvalAmount);
    }
    
    function test_Approve_EmitsApprovalEvent() public {
        uint256 approvalAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, approvalAmount);
        
        token.approve(alice, approvalAmount);
    }
    
    function test_Approve_RevertsWhenSpenderIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0))
        );
        token.approve(address(0), 1000);
    }
    
    function test_Approve_AllowsZeroApproval() public {
        token.approve(alice, 1000);
        bool success = token.approve(alice, 0);
        
        assertTrue(success);
        assertEq(token.allowance(owner, alice), 0);
    }
    
    function test_Approve_AllowsMaxUint256() public {
        bool success = token.approve(alice, type(uint256).max);
        
        assertTrue(success);
        assertEq(token.allowance(owner, alice), type(uint256).max);
    }
    
    function test_Approve_OverwritesPreviousAllowance() public {
        token.approve(alice, 1000);
        token.approve(alice, 2000);
        
        assertEq(token.allowance(owner, alice), 2000);
    }
    
    function testFuzz_Approve_SetsArbitraryAllowance(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        
        token.approve(spender, amount);
        
        assertEq(token.allowance(owner, spender), amount);
    }
    
    // ============ Allowance Tests ============
    
    function test_Allowance_ReturnsZeroByDefault() public view {
        assertEq(token.allowance(owner, alice), 0);
    }
    
    function test_Allowance_ReturnsCorrectValue() public {
        uint256 approvalAmount = 1000 * 10**18;
        token.approve(alice, approvalAmount);
        
        assertEq(token.allowance(owner, alice), approvalAmount);
    }
    
    function test_Allowance_IndependentForDifferentSpenders() public {
        token.approve(alice, 1000);
        token.approve(bob, 2000);
        
        assertEq(token.allowance(owner, alice), 1000);
        assertEq(token.allowance(owner, bob), 2000);
    }
    
    // ============ TransferFrom Tests ============
    
    function test_TransferFrom_SuccessfulTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        token.approve(alice, transferAmount);
        
        vm.prank(alice);
        bool success = token.transferFrom(owner, bob, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
    }
    
    function test_TransferFrom_DecreasesAllowance() public {
        uint256 approvalAmount = 2000 * 10**18;
        uint256 transferAmount = 1000 * 10**18;
        token.approve(alice, approvalAmount);
        
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        assertEq(token.allowance(owner, alice), approvalAmount - transferAmount);
    }
    
    function test_TransferFrom_EmitsTransferEvent() public {
        uint256 transferAmount = 1000 * 10**18;
        token.approve(alice, transferAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, bob, transferAmount);
        
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
    }
    
    function test_TransferFrom_DoesNotEmitApprovalEventForNonMaxAllowance() public {
        uint256 transferAmount = 1000 * 10**18;
        token.approve(alice, transferAmount);
        
        // No Approval event should be emitted
        vm.recordLogs();
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        Vm.Log[] memory logs = vm.getRecordedLogs();
        // Only Transfer event should be present
        assertEq(logs.length, 1);
        assertEq(logs[0].topics[0], keccak256("Transfer(address,address,uint256)"));
    }
    
    function test_TransferFrom_RevertsWhenInsufficientAllowance() public {
        token.approve(alice, 500 * 10**18);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                alice,
                500 * 10**18,
                1000 * 10**18
            )
        );
        
        vm.prank(alice);
        token.transferFrom(owner, bob, 1000 * 10**18);
    }
    
    function test_TransferFrom_RevertsWhenInsufficientBalance() public {
        token.approve(alice, INITIAL_SUPPLY + 1);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                owner,
                INITIAL_SUPPLY,
                INITIAL_SUPPLY + 1
            )
        );
        
        vm.prank(alice);
        token.transferFrom(owner, bob, INITIAL_SUPPLY + 1);
    }
    
    function test_TransferFrom_RevertsWhenToIsZeroAddress() public {
        token.approve(alice, 1000);
        
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0))
        );
        
        vm.prank(alice);
        token.transferFrom(owner, address(0), 1000);
    }
    
    function test_TransferFrom_RevertsWhenFromIsZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0))
        );
        token.transferFrom(address(0), bob, 1000);
    }
    
    function test_TransferFrom_WithMaxAllowanceDoesNotDecreaseAllowance() public {
        uint256 transferAmount = 1000 * 10**18;
        token.approve(alice, type(uint256).max);
        
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        assertEq(token.allowance(owner, alice), type(uint256).max);
    }
    
    function test_TransferFrom_AllowsZeroValueTransfer() public {
        token.approve(alice, 1000);
        
        vm.prank(alice);
        bool success = token.transferFrom(owner, bob, 0);
        
        assertTrue(success);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.allowance(owner, alice), 1000);
    }
    
    function test_TransferFrom_MultipleTransfersWithinAllowance() public {
        token.approve(alice, 3000 * 10**18);
        
        vm.startPrank(alice);
        token.transferFrom(owner, bob, 1000 * 10**18);
        token.transferFrom(owner, bob, 1000 * 10**18);
        token.transferFrom(owner, bob, 1000 * 10**18);
        vm.stopPrank();
        
        assertEq(token.balanceOf(bob), 3000 * 10**18);
        assertEq(token.allowance(owner, alice), 0);
    }
    
    function testFuzz_TransferFrom_CorrectBalanceAndAllowanceUpdates(
        uint128 approvalAmount,
        uint128 transferAmount
    ) public {
        vm.assume(transferAmount <= approvalAmount);
        vm.assume(transferAmount <= INITIAL_SUPPLY);
        vm.assume(approvalAmount < type(uint256).max);
        
        token.approve(alice, approvalAmount);
        
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), approvalAmount - transferAmount);
    }
    
    // ============ Internal _mint Tests ============
    
    function test_Mint_IncreasesTotalSupply() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        token.mint(alice, mintAmount);
        
        assertEq(token.totalSupply(), initialSupply + mintAmount);
    }
    
    function test_Mint_IncreasesBalance() public {
        uint256 mintAmount = 1000 * 10**18;
        
        token.mint(alice, mintAmount);
        
        assertEq(token.balanceOf(alice), mintAmount);
    }
    
    function test_Mint_EmitsTransferEvent() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, mintAmount);
        
        token.mint(alice, mintAmount);
    }
    
    function test_Mint_RevertsWhenAccountIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0))
        );
        token.mint(address(0), 1000);
    }
    
    function test_Mint_AllowsZeroAmount() public {
        token.mint(alice, 0);
        assertEq(token.balanceOf(alice), 0);
    }
    
    function testFuzz_Mint_CorrectStateUpdates(address account, uint128 amount) public {
        vm.assume(account != address(0));
        vm.assume(amount < type(uint256).max - token.totalSupply());
        
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(account);
        
        token.mint(account, amount);
        
        assertEq(token.totalSupply(), initialSupply + amount);
        assertEq(token.balanceOf(account), initialBalance + amount);
    }
    
    // ============ Internal _burn Tests ============
    
    function test_Burn_DecreasesTotalSupply() public {
        uint256 burnAmount = 1000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        token.burn(owner, burnAmount);
        
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }
    
    function test_Burn_DecreasesBalance() public {
        uint256 burnAmount = 1000 * 10**18;
        
        token.burn(owner, burnAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
    }
    
    function test_Burn_EmitsTransferEvent() public {
        uint256 burnAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);
        
        token.burn(owner, burnAmount);
    }
    
    function test_Burn_RevertsWhenAccountIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0))
        );
        token.burn(address(0), 1000);
    }
    
    function test_Burn_RevertsWhenInsufficientBalance() public {
        token.mint(alice, 500 * 10**18);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                alice,
                500 * 10**18,
                1000 * 10**18
            )
        );
        
        token.burn(alice, 1000 * 10**18);
    }
    
    function test_Burn_AllowsZeroAmount() public {
        uint256 initialBalance = token.balanceOf(owner);
        token.burn(owner, 0);
        assertEq(token.balanceOf(owner), initialBalance);
    }
    
    function test_Burn_AllowsBurnEntireBalance() public {
        token.burn(owner, INITIAL_SUPPLY);
        
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.totalSupply(), 0);
    }
    
    function testFuzz_Burn_CorrectStateUpdates(uint128 amount) public {
        vm.assume(amount <= INITIAL_SUPPLY);
        
        uint256 initialSupply = token.totalSupply();
        
        token.burn(owner, amount);
        
        assertEq(token.totalSupply(), initialSupply - amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }
    
    // ============ Internal _approve Tests ============
    
    function test_ApproveInternal_SetsAllowance() public {
        uint256 approvalAmount = 1000 * 10**18;
        
        token.approveInternal(alice, bob, approvalAmount);
        
        assertEq(token.allowance(alice, bob), approvalAmount);
    }
    
    function test_ApproveInternal_EmitsApprovalEvent() public {
        uint256 approvalAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, approvalAmount);
        
        token.approveInternal(alice, bob, approvalAmount);
    }
    
    function test_ApproveInternal_RevertsWhenOwnerIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidApprover.selector, address(0))
        );
        token.approveInternal(address(0), alice, 1000);
    }
    
    function test_ApproveInternal_RevertsWhenSpenderIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0))
        );
        token.approveInternal(alice, address(0), 1000);
    }
    
    // ============ Internal _transfer Tests ============
    
    function test_TransferInternal_TransfersCorrectly() public {
        token.mint(alice, 1000 * 10**18);
        
        token.transferInternal(alice, bob, 500 * 10**18);
        
        assertEq(token.balanceOf(alice), 500 * 10**18);
        assertEq(token.balanceOf(bob), 500 * 10**18);
    }
    
    function test_TransferInternal_RevertsWhenFromIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidSender.selector, address(0))
        );
        token.transferInternal(address(0), alice, 1000);
    }
    
    function test_TransferInternal_RevertsWhenToIsZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0))
        );
        token.transferInternal(owner, address(0), 1000);
    }
    
    // ============ Internal _spendAllowance Tests ============
    
    function test_SpendAllowance_DecreasesAllowance() public {
        token.approve(alice, 2000 * 10**18);
        
        token.spendAllowanceInternal(owner, alice, 1000 * 10**18);
        
        assertEq(token.allowance(owner, alice), 1000 * 10**18);
    }
    
    function test_SpendAllowance_DoesNotDecreaseMaxAllowance() public {
        token.approve(alice, type(uint256).max);
        
        token.spendAllowanceInternal(owner, alice, 1000 * 10**18);
        
        assertEq(token.allowance(owner, alice), type(uint256).max);
    }
    
    function test_SpendAllowance_RevertsWhenInsufficientAllowance() public {
        token.approve(alice, 500 * 10**18);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                alice,
                500 * 10**18,
                1000 * 10**18
            )
        );
        
        token.spendAllowanceInternal(owner, alice, 1000 * 10**18);
    }
    
    function test_SpendAllowance_AllowsSpendingExactAllowance() public {
        token.approve(alice, 1000 * 10**18);
        
        token.spendAllowanceInternal(owner, alice, 1000 * 10**18);
        
        assertEq(token.allowance(owner, alice), 0);
    }
    
    // ============ Complex Scenario Tests ============
    
    function test_ComplexScenario_MultipleUsersTransfers() public {
        // Setup: distribute tokens
        token.transfer(alice, 10000 * 10**18);
        token.transfer(bob, 10000 * 10**18);
        
        // Alice approves Charlie
        vm.prank(alice);
        token.approve(charlie, 5000 * 10**18);
        
        // Charlie transfers from Alice to Bob
        vm.prank(charlie);
        token.transferFrom(alice, bob, 3000 * 10**18);
        
        // Verify final state
        assertEq(token.balanceOf(alice), 7000 * 10**18);
        assertEq(token.balanceOf(bob), 13000 * 10**18);
        assertEq(token.allowance(alice, charlie), 2000 * 10**18);
    }
    
    function test_ComplexScenario_MintBurnTransferCycle() public {
        // Mint new tokens
        token.mint(alice, 5000 * 10**18);
        
        // Transfer some
        vm.prank(alice);
        token.transfer(bob, 2000 * 10**18);
        
        // Burn some
        token.burn(alice, 1000 * 10**18);
        
        // Verify final state
        assertEq(token.balanceOf(alice), 2000 * 10**18);
        assertEq(token.balanceOf(bob), 2000 * 10**18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 4000 * 10**18);
    }
    
    function test_ComplexScenario_ApprovalChain() public {
        // Owner approves Alice
        token.approve(alice, 5000 * 10**18);
        
        // Alice uses part of allowance
        vm.prank(alice);
        token.transferFrom(owner, bob, 2000 * 10**18);
        
        // Owner increases allowance
        token.approve(alice, 8000 * 10**18);
        
        // Alice uses more
        vm.prank(alice);
        token.transferFrom(owner, charlie, 3000 * 10**18);
        
        // Verify
        assertEq(token.allowance(owner, alice), 5000 * 10**18);
        assertEq(token.balanceOf(bob), 2000 * 10**18);
        assertEq(token.balanceOf(charlie), 3000 * 10**18);
    }
    
    // ============ Edge Case Tests ============
    
    function test_EdgeCase_TransferToSelf() public {
        uint256 amount = 1000 * 10**18;
        uint256 initialBalance = token.balanceOf(owner);
        
        token.transfer(owner, amount);
        
        assertEq(token.balanceOf(owner), initialBalance);
    }
    
    function test_EdgeCase_ApproveToSelf() public {
        uint256 amount = 1000 * 10**18;
        
        token.approve(owner, amount);
        
        assertEq(token.allowance(owner, owner), amount);
    }
    
    function test_EdgeCase_TransferFromToSameAddress() public {
        token.mint(alice, 1000 * 10**18);
        
        vm.prank(alice);
        token.approve(owner, 500 * 10**18);
        
        token.transferFrom(alice, alice, 500 * 10**18);
        
        assertEq(token.balanceOf(alice), 1000 * 10**18);
    }
    
    function test_EdgeCase_MultipleApprovalsToSameSpender() public {
        token.approve(alice, 1000 * 10**18);
        token.approve(alice, 2000 * 10**18);
        token.approve(alice, 3000 * 10**18);
        
        assertEq(token.allowance(owner, alice), 3000 * 10**18);
    }
    
    function test_EdgeCase_MaxUint256Supply() public {
        // This tests overflow protection in mint
        ERC20Mock newToken = new ERC20Mock("Overflow Test", "OVF");
        
        // Mint near max
        newToken.mint(alice, type(uint256).max - 1);
        
        // Should work
        newToken.mint(bob, 1);
        
        // Verify
        assertEq(newToken.totalSupply(), type(uint256).max);
    }
    
    // ============ Gas Optimization Tests ============
    
    function test_Gas_SimpleTransfer() public {
        uint256 gasBefore = gasleft();
        token.transfer(alice, 1000 * 10**18);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Just log for information
        emit log_named_uint("Gas used for transfer", gasUsed);
    }
    
    function test_Gas_TransferFrom() public {
        token.approve(alice, 1000 * 10**18);
        
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        token.transferFrom(owner, bob, 1000 * 10**18);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("Gas used for transferFrom", gasUsed);
    }
    
    function test_Gas_Approve() public {
        uint256 gasBefore = gasleft();
        token.approve(alice, 1000 * 10**18);
        uint256 gasUsed = gasBefore - gasleft();
        
        emit log_named_uint("Gas used for approve", gasUsed);
    }
    
    // ============ Interface Compliance Tests ============
    
    function test_Interface_SupportsIERC20() public view {
        // Verify all IERC20 functions exist
        token.totalSupply();
        token.balanceOf(owner);
        token.allowance(owner, alice);
        // transfer, approve, transferFrom are tested above
    }
    
    function test_Interface_SupportsIERC20Metadata() public view {
        // Verify all IERC20Metadata functions exist
        token.name();
        token.symbol();
        token.decimals();
    }
}