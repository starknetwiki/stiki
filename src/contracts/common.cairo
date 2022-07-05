%lang starknet

from starkware.cairo.common.dict import DictAccess
from starkware.cairo.common.uint256 import Uint256

struct StikiEditState:
    # The hash of a Stiki
    member stiki_hash : Uint256
    # The number of upvotes
    member n_upvotes : felt
    # The number of downvotes
    member n_downvotes : felt
end
