%lang starknet

from starkware.cairo.common.dict import DictAccess
from starkware.cairo.common.uint256 import Uint256

struct StikiEditState:
    # The hash of a StikiEdit
    member previous_stiki_hash : Uint256
    # The address of a scholar
    member scholar_address : felt
    # The number of weighted upvotes
    member w_upvotes : felt
    # The number of weighted downvotes
    member w_downvotes : felt
end

struct ScholarReputation:
    # Game mastery level
    member level : felt
    # Total experience points
    member xp : felt
    # The number of edits
    member n_edits : felt
    # The number of received upvotes
    member r_upvotes : felt
    # The number of received downvotes
    member r_downvotes : felt
end

struct VoteContext:
    member edit_state : StikiEditState
    member voter_reputation : ScholarReputation
    member contributor_reputation : ScholarReputation
end
