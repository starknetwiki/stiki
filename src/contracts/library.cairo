%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address

# Local Dependencies
from src.contracts.common import StikiEditState
from src.contracts.accesscontrol import StikiAccessControl

# Open Zeppelin Dependencies
from openzeppelin.access.ownable import Ownable

# ------------
# STORAGE VARS
# ------------

# Current Stiki
@storage_var
func stiki_(game_address : felt) -> (stiki_hash : Uint256):
end

# State of the Stiki edit
@storage_var
func stiki_edit_state_(game_address : felt) -> (stiki_edit_state : StikiEditState):
end

# ------
# EVENTS
# ------
@event
func upvoted(caller_address : felt, stiki_hash : Uint256):
end

@event
func downvoted(caller_address : felt, stiki_hash : Uint256):
end

namespace Stiki:
    # -----
    # VIEWS
    # -----
    func stiki{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ) -> (stiki_hash : Uint256):
        let (stiki_hash) = stiki_.read(game_address)
        return (stiki_hash)
    end

    func stiki_edit_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ) -> (stiki_edit_state : StikiEditState):
        let (stiki_edit_state) = stiki_edit_state_.read(game_address)
        return (stiki_edit_state)
    end

    func stiki_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (stiki_owner : felt):
        let (stiki_owner) = Ownable.owner()
        return (stiki_owner)
    end

    func stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ) -> (stiki_admin : felt):
        let (stiki_admin) = StikiAccessControl.stiki_admin(game_address)
        return (stiki_admin)
    end

    # -----------
    # CONSTRUCTOR
    # -----------
    func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt
    ):
        Ownable.initializer(owner)
        return ()
    end

    # ---------
    # EXTERNALS
    # ---------
    func set_stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt, stiki_admin : felt
    ):
        return StikiAccessControl.set_stiki_admin(game_address, stiki_admin)
    end

    func upvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ):
        # TODO: Put access control for upvoting i.e. scholar score, existing player, etc.
        let (caller) = get_caller_address()
        let (stiki_edit_state) = stiki_edit_state_.read(game_address)

        # increment upvote by 1
        stiki_edit_state_.write(
            game_address,
            StikiEditState(
                stiki_edit_state.stiki_hash,
                stiki_edit_state.n_upvotes+1,
                stiki_edit_state.n_downvotes
            )
        )

        # emit upvoted event
        upvoted.emit(caller, stiki_edit_state.stiki_hash)
        return ()
    end

    func downvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ):
        # TODO: Put access control for upvoting i.e. scholar score, existing player, etc.
        let (caller) = get_caller_address()
        let (stiki_edit_state) = stiki_edit_state_.read(game_address)

        # increment downvote by 1
        stiki_edit_state_.write(
            game_address,
            StikiEditState(
                stiki_edit_state.stiki_hash,
                stiki_edit_state.n_upvotes,
                stiki_edit_state.n_downvotes+1
            )
        )

        # emit downvoted event
        downvoted.emit(caller, stiki_edit_state.stiki_hash)
        return ()
    end

    # TODO: Set new stiki hash based on votes
end # end namespace
