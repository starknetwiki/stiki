%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

# Stiki
from src.contracts.common import StikiEditState
from src.contracts.library import Stiki

# ---------
# CONSTANTS
# ---------
const OWNER = 123
const ADMIN = 124
const ANYONE = 125
const GAME_ADDRESS = 0x42069

# -------
# STRUCTS
# -------
struct Signers:
    member owner : felt
    member admin : felt
    member anyone : felt
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
@view
func test_upvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare()
    local stiki_edit_state : StikiEditState = StikiEditState(context.mocks.new_stiki_hash, 0, 0)

    # Anyone upvotes stiki edit
    %{ stop_prank_anyone = start_prank(ids.context.signers.anyone) %}
    Stiki.upvote(context.mocks.game_address)
    %{ stop_prank_anyone() %}

    # Assert upvote increased by one
    let (stiki_edit_state) = Stiki.stiki_edit_state(context.mocks.game_address)
    assert 1 = stiki_edit_state.n_upvotes

    return ()
end

@view
func test_downvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare()
    local stiki_edit_state : StikiEditState = StikiEditState(context.mocks.new_stiki_hash, 0, 0)

    # Anyone downvotes stiki edit
    %{ stop_prank_anyone = start_prank(ids.context.signers.anyone) %}
    Stiki.downvote(context.mocks.game_address)
    %{ stop_prank_anyone() %}

    # Assert upvote increased by one
    let (stiki_edit_state) = Stiki.stiki_edit_state(context.mocks.game_address)
    assert 1 = stiki_edit_state.n_downvotes

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
            anyone=ANYONE
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
end # end namespace
