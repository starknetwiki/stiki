%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address

# Stiki
from src.contracts.library import Stiki
from src.contracts.common import (
    StikiEditState,
    ScholarReputation,
    VoteContext,
)
from src.interfaces.Istiki import IStiki

# ---------
# CONSTANTS
# ---------
const OWNER = 123
const ADMIN = 124
const PLAYER_1 = 125 # contributor
const PLAYER_2 = 126 # voter
const GAME_ADDRESS = 0x42069

# -------
# STRUCTS
# -------
struct Signers:
    member owner : felt
    member admin : felt
    member player_1 : felt
    member player_2 : felt
end

struct Mocks:
    member game_address : felt
    member current_stiki_hash : Uint256
    member new_stiki_hash : Uint256
end

struct TestContext:
    member signers : Signers
    member mocks : Mocks
end

# -----
# TESTS
# -----

# Deploy Stiki contract
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tempvar stiki_contract
    %{
        ids.stiki_contract = deploy_contract("./src/contracts/stiki.cairo", { "owner": ids.OWNER }).contract_address 
        context.stiki_contract = ids.stiki_contract
    %}
    return ()
end

@view
func test_upvote_per_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (stiki_contract) = stiki.deployed()
    let stiki_hash = Uint256(420, 69)

    with stiki_contract:
        test_internal.upvote_and_check_expected_per_level(
            GAME_ADDRESS,
            stiki_hash,
            # expected w_upvotes
            new (1, 1, 2, 3, 5, 8),
            6
        )
    end

    return ()
end

@view
func test_downvote_per_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (stiki_contract) = stiki.deployed()
    let stiki_hash = Uint256(420, 69)

    with stiki_contract:
        test_internal.downvote_and_check_expected_per_level(
            GAME_ADDRESS,
            stiki_hash,
            # expected w_downvotes
            new (1, 1, 2, 3, 5, 8),
            6
        )
    end

    return ()
end

# -----------------------
# INTERNAL TEST FUNCTIONS
# -----------------------

namespace test_internal:
    func prepare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (test_context : TestContext):
        alloc_locals
        local signers : Signers = Signers(
            owner=OWNER,
            admin=ADMIN,
            player_1=PLAYER_1,
            player_2=PLAYER_2
        )

        local mocks : Mocks = Mocks(
            game_address=GAME_ADDRESS,
            current_stiki_hash=Uint256(1,2),
            new_stiki_hash=Uint256(1,3)
        )

        local test_context : TestContext = TestContext(
            signers=signers,
            mocks=mocks
        )

        Stiki.constructor(
            signers.owner
        )

        let (stiki_owner) = Stiki.stiki_owner()
        assert signers.owner = stiki_owner
        return (test_context)
    end

    func upvote_and_check_expected_per_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, stiki_contract : felt}(
        game_address : felt, stiki_hash : Uint256, expected_votes : felt*, expected_votes_len : felt
    ):
        alloc_locals

        if expected_votes_len == 0:
            return ()
        end

        # Vote and check with expected votes
        stiki.upvote(game_address, stiki_hash)
        let (edit_state) = stiki.stiki_edit_state(game_address, stiki_hash)
        assert [expected_votes] = edit_state.w_upvotes

        # Level up
        stiki.level_up(game_address)

        # Vote on different Stiki Hash and Recurse
        let one = Uint256(1,0)
        let (stiki_hash,_) = uint256_add(stiki_hash, one)
        upvote_and_check_expected_per_level(game_address, stiki_hash, expected_votes+1, expected_votes_len-1)
        return ()
    end

    func downvote_and_check_expected_per_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, stiki_contract : felt}(
        game_address : felt, stiki_hash : Uint256, expected_votes : felt*, expected_votes_len : felt
    ):
        alloc_locals

        if expected_votes_len == 0:
            return ()
        end

        # Vote and check with expected votes
        stiki.downvote(game_address, stiki_hash)
        let (edit_state) = stiki.stiki_edit_state(game_address, stiki_hash)
        assert [expected_votes] = edit_state.w_downvotes

        # Level up
        stiki.level_up(game_address)

        # Vote on different Stiki Hash and Recurse
        let one = Uint256(1,0)
        let (stiki_hash,_) = uint256_add(stiki_hash, one)
        downvote_and_check_expected_per_level(game_address, stiki_hash, expected_votes+1, expected_votes_len-1)
        return ()
    end

end # end namespace


# ------------------
# DEPLOYED CONTRACTS
# ------------------
namespace stiki:
    func deployed() -> (stiki_contract : felt):
        tempvar stiki_contract
        %{ ids.stiki_contract = context.stiki_contract %}
        return (stiki_contract)
    end

    func stiki_edit_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, stiki_contract : felt}(
        game_address : felt, stiki_hash : Uint256
    ) -> (stiki_edit_state : StikiEditState):
        let (stiki_edit_state) = IStiki.stiki_edit_state(stiki_contract, game_address, stiki_hash)
        return (stiki_edit_state)
    end

    func upvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, stiki_contract : felt}(
        game_address : felt, stiki_hash : Uint256
    ):
        %{ stop_prank_player_2 = start_prank(ids.PLAYER_2, ids.stiki_contract) %}
        IStiki.upvote(stiki_contract, game_address, stiki_hash)
        %{ stop_prank_player_2() %}
        return ()
    end

    func downvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, stiki_contract : felt}(
        game_address : felt, stiki_hash : Uint256
    ):
        %{ stop_prank_player_2 = start_prank(ids.PLAYER_2, ids.stiki_contract) %}
        IStiki.downvote(stiki_contract, game_address, stiki_hash)
        %{ stop_prank_player_2() %}
        return ()
    end

    func level_up{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, stiki_contract : felt}(
        game_address : felt
    ):
        %{ stop_prank_player_2 = start_prank(ids.PLAYER_2, ids.stiki_contract) %}
        IStiki.level_up(stiki_contract, game_address)
        %{ stop_prank_player_2() %}
        return ()
    end
end # end namespace
