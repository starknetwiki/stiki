%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero

# Open Zeppelin Dependencies
from openzeppelin.access.ownable import Ownable

# ------------
# STORAGE VARS
# ------------

# Stiki Admin
@storage_var
func stiki_admin_(game_address : felt) -> (stiki_admin : felt):
end

# ------
# EVENTS
# ------
@event
func stiki_admin_set(previous_stiki_admin : felt, new_stiki_admin : felt):
end

namespace StikiAccessControl:
    # -----
    # VIEWS
    # -----
    func stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ) -> (stiki_admin : felt):
        let (stiki_admin) = stiki_admin_.read(game_address)
        return (stiki_admin)
    end

    # --------
    # External
    # --------
    func set_stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt, stiki_admin : felt
    ):
        Ownable.assert_only_owner()
        with_attr error_message("StikiAccessControl: admin cannot be zero address"):
            assert_not_zero(stiki_admin)
        end
        stiki_admin_.write(game_address, stiki_admin)

        # emit event
        let (previous_stiki_admin) = stiki_admin_.read(game_address)
        stiki_admin_set.emit(previous_stiki_admin, stiki_admin)
        return ()
    end

    # --------------
    # ACCESS CONTROL
    # --------------
    func assert_only_stiki_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt
    ):
        let (stiki_admin) = stiki_admin_.read(game_address)
        let (caller) = get_caller_address()
        with_attr error_message("StikiAccessControl: caller is not the stiki admin"):
            assert stiki_admin = caller
        end
        return ()
    end
end  # end namespace
