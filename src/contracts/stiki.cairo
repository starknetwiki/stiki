%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.contracts.common import StikiEditState
from starkware.cairo.common.uint256 import Uint256
from src.contracts.library import Stiki

# -----
# VIEWS
# -----
@view
func stiki{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_address
) -> (stiki_hash : Uint256):
    return Stiki.stiki(game_address)
end

@view
func stiki_edit_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_address
) -> (stiki_edit_state : StikiEditState):
    return Stiki.stiki_edit_state(game_address)
end

@view
func stiki_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
) -> (stiki_owner : felt):
    return Stiki.stiki_owner()
end

@view
func stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_address
) -> (stiki_admin : felt):
    return Stiki.stiki_admin(game_address)
end

# -----------
# CONSTRUCTOR
# -----------
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt
):
    return Stiki.constructor(owner)
end

# ---------
# EXTERNALS
# ---------
@external
func set_stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_address : felt, stiki_admin : felt
):
    return Stiki.set_stiki_admin(game_address, stiki_admin)
end

@external
func upvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_address : felt
):
    return Stiki.upvote(game_address)
end

@external
func downvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_address : felt
):
    return Stiki.downvote(game_address)
end
