%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.contracts.common import StikiEditState, ScholarReputation

@contract_interface
namespace IStiki:
    # -----
    # VIEWS
    # -----
    func stiki(game_address : felt) -> (stiki_hash : Uint256):
    end

    func stiki_edit_state(game_address : felt, stiki_hash : Uint256) -> (stiki_edit_state : StikiEditState):
    end

    func stiki_scholar_reputation(game_address : felt, scholar_address : felt) -> (stiki_scholar_reputation : ScholarReputation):
    end

    func has_voted_on_stiki(game_address : felt, scholar_address : felt, stiki_hash : Uint256) -> (has_voted : felt):
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

    func upvote(game_address : felt, stiki_hash : Uint256):
    end

    func downvote(game_address : felt, stiki_hash : Uint256):
    end

    func level_up(game_address : felt):
    end
end
