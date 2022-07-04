%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.contracts.common import StikiEditState

@contract_interface
namespace IStiki:
    # -----
    # VIEWS
    # -----
    func stiki(game_address : felt) -> (stiki_hash : Uint256):
    end

    func stiki_edit_state(game_address : felt) -> (stiki_edit_state : StikiEditState):
    end

    func stiki_owner() -> (stiki_owner : felt):
    end

    func stiki_admin(game_address : felt) -> (stiki_admin : felt):
    end

    # ---------
    # EXTERNALS
    # ---------
    func set_stiki_admin(game_address : felt, stiki_admin):
    end

    func upvote(game_address : felt):
    end

    func downvote(game_address : felt):
    end
end
