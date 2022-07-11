%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.registers import get_label_location

# Local Dependencies
from src.contracts.accesscontrol import StikiAccessControl
from src.contracts.common import (
    StikiEditState,
    ScholarReputation,
    VoteContext,
)
from src.contracts.constants import LevelMultiplier

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
func stiki_edit_state_(game_address : felt, stiki_hash : Uint256) -> (stiki_edit_state : StikiEditState):
end

# Scholar's reputation for a game
@storage_var
func stiki_scholar_reputation_(game_address : felt, scholar_address : felt) -> (stiki_scholar_reputation : ScholarReputation):
end

# Has voted for a Stiki
@storage_var
func has_voted_on_stiki_(game_address : felt, scholar_addres : felt, stiki_hash : Uint256) -> (has_voted : felt):
end

# ------
# EVENTS
# ------
@event
func upvoted(voter_address : felt, scholar_address :felt, stiki_hash : Uint256):
end

@event
func downvoted(voter_address : felt, scholar_address :felt, stiki_hash : Uint256):
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
        game_address : felt, stiki_hash : Uint256
    ) -> (stiki_edit_state : StikiEditState):
        let (stiki_edit_state) = stiki_edit_state_.read(game_address, stiki_hash)
        return (stiki_edit_state)
    end

    func stiki_scholar_reputation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt, scholar_address : felt
    ) -> (stiki_scholar_reputation : ScholarReputation):
        let (stiki_scholar_reputation) = stiki_scholar_reputation_.read(game_address, scholar_address)
        return (stiki_scholar_reputation)
    end

    func has_voted_on_stiki{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt, scholar_address : felt, stiki_hash : Uint256
    ) -> (has_voted : felt):
        let (has_voted_on_stiki) = has_voted_on_stiki_.read(game_address, scholar_address, stiki_hash)
        return (has_voted_on_stiki)
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

    # func edit_stiki{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    #     game_address : felt
    # ):
    #     # TODO: Add logic for generating hash
    #     stiki_edit_state_.write(
    # end

    func upvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt, stiki_hash : Uint256
    ):
        alloc_locals
        # TODO: Put access control for upvoting i.e. scholar score, existing player, etc.
        let (voter) = get_caller_address()
        let (edit_state) = stiki_edit_state(game_address, stiki_hash)

        # Get Scholar Reputation both voter and contributor
        let (voter_reputation) = stiki_scholar_reputation(game_address, voter)
        let (contributor_reputation) = stiki_scholar_reputation(game_address, edit_state.scholar_address)

        # Weighted vote
        let vote_context : VoteContext = VoteContext(
            edit_state,
            voter_reputation,
            contributor_reputation,
        )

        # Update StikiEditState with weighted voting and ScholarReputation
        with vote_context:
            internal.set_has_voted_on_stiki(game_address, edit_state.scholar_address, stiki_hash)
            internal.weighted_vote('upvote')
            stiki_edit_state_.write(game_address, stiki_hash, vote_context.edit_state)
            stiki_scholar_reputation_.write(game_address, edit_state.scholar_address, vote_context.contributor_reputation)
        end

        # Emit upvote event
        upvoted.emit(voter, edit_state.scholar_address, stiki_hash)

        return ()
    end

    func downvote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        game_address : felt, stiki_hash : Uint256
    ):
        alloc_locals
        # TODO: Put access control for upvoting i.e. scholar score, existing player, etc.
        let (voter) = get_caller_address()
        let (edit_state) = stiki_edit_state(game_address, stiki_hash)

        # Get Scholar Reputation both voter and contributor
        let (voter_reputation) = stiki_scholar_reputation(game_address, voter)
        let (contributor_reputation) = stiki_scholar_reputation(game_address, edit_state.scholar_address)

        # Weighted vote
        let vote_context : VoteContext = VoteContext(
            edit_state,
            voter_reputation,
            contributor_reputation,
        )

        # Update StikiEditState with weighted voting and ScholarReputation
        with vote_context:
            internal.set_has_voted_on_stiki(game_address, edit_state.scholar_address, stiki_hash)
            internal.weighted_vote('downvote')
            stiki_edit_state_.write(game_address, stiki_hash, vote_context.edit_state)
            stiki_scholar_reputation_.write(game_address, edit_state.scholar_address, vote_context.contributor_reputation)
        end

        # Emit downvote event
        downvoted.emit(voter, edit_state.scholar_address, stiki_hash)

        return ()
    end

    # TODO: Set new stiki hash based on votes

    # ---------
    # INTERNALS
    # ---------
    namespace internal:
        func weighted_vote{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            vote_context : VoteContext,
            }(type : felt):
            alloc_locals

            # Assert only upvote or downvote type
            with_attr error_message("Stiki: vote type only either upvote or downvote"):
                assert 0 = (type - 'upvote') * (type - 'downvote')
            end

            # Calculate weighted vote
            # weight * 1 vote = w_vote
            # TODO: Add more business logic
            let (w_vote) = internal.multiplier(vote_context.voter_reputation.level)

            # Update the following:
            # 1. Weighted votes of StikiEditState
            # 2. ScholarReputation of contributor
            # 3. ScholarReputation of voter
            local new_edit_state : StikiEditState
            local new_contributor_reputation : ScholarReputation
            local new_voter_reputation : ScholarReputation
            if type == 'upvote':

                # TODO: Refactor
                # StikiEditState
                assert new_edit_state.previous_stiki_hash = vote_context.edit_state.previous_stiki_hash
                assert new_edit_state.scholar_address = vote_context.edit_state.scholar_address
                assert new_edit_state.w_upvotes = vote_context.edit_state.w_upvotes + w_vote
                assert new_edit_state.w_downvotes = vote_context.edit_state.w_downvotes
                # ScholarReputation Contributor
                assert new_contributor_reputation.level = vote_context.contributor_reputation.level
                assert new_contributor_reputation.xp = vote_context.contributor_reputation.xp + 1
                assert new_contributor_reputation.n_edits = vote_context.contributor_reputation.n_edits
                assert new_contributor_reputation.r_upvotes = vote_context.contributor_reputation.r_upvotes + 1
                assert new_contributor_reputation.r_downvotes = vote_context.contributor_reputation.r_downvotes
                # ScholarReputation Voter
                assert new_voter_reputation.level = vote_context.voter_reputation.level
                assert new_voter_reputation.xp = vote_context.voter_reputation.xp + 1
                assert new_voter_reputation.n_edits = vote_context.voter_reputation.n_edits
                assert new_voter_reputation.r_upvotes = vote_context.voter_reputation.r_upvotes
                assert new_voter_reputation.r_downvotes = vote_context.voter_reputation.r_downvotes
            else:
                # StikiEditState
                assert new_edit_state.previous_stiki_hash = vote_context.edit_state.previous_stiki_hash
                assert new_edit_state.scholar_address = vote_context.edit_state.scholar_address
                assert new_edit_state.w_upvotes = vote_context.edit_state.w_upvotes
                assert new_edit_state.w_downvotes = vote_context.edit_state.w_downvotes + w_vote
                # ScholarReputation
                assert new_contributor_reputation.level = vote_context.contributor_reputation.level
                assert new_contributor_reputation.xp = vote_context.contributor_reputation.xp
                assert new_contributor_reputation.n_edits = vote_context.contributor_reputation.n_edits
                assert new_contributor_reputation.r_upvotes = vote_context.contributor_reputation.r_upvotes
                assert new_contributor_reputation.r_downvotes = vote_context.contributor_reputation.r_downvotes + 1
            end

            let vote_context = VoteContext(
                new_edit_state,
                vote_context.voter_reputation,
                new_contributor_reputation
            )
            return ()
        end

        func set_has_voted_on_stiki{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(game_address : felt, scholar_address : felt, stiki_hash : Uint256):
            let (has_voted) = has_voted_on_stiki(game_address, scholar_address, stiki_hash)
            with_attr error_message("Stiki: has already voted"):
                assert 0 = has_voted
            end

            has_voted_on_stiki_.write(game_address, scholar_address, stiki_hash, 1)
            return ()
        end

        # For testing for now
        func level_up{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(game_address : felt):
            let (caller) = get_caller_address()
            let (caller_reputation) = stiki_scholar_reputation_.read(game_address, caller)
            stiki_scholar_reputation_.write(
                game_address,
                caller,
                ScholarReputation(
                    caller_reputation.level+1,
                    caller_reputation.xp,
                    caller_reputation.n_edits,
                    caller_reputation.r_upvotes,
                    caller_reputation.r_downvotes
                )
            )
            return ()
        end

        func multiplier{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(level : felt) -> (multiplier : felt):
            alloc_locals

            let (multiplier_label) = get_label_location(level_multiplier)

            return ([multiplier_label + level])

            # Get level multiplier for vote weighting
            # starting with level = 0 as Level.ZERO
            level_multiplier:
            dw LevelMultiplier.ZERO
            dw LevelMultiplier.ONE
            dw LevelMultiplier.TWO
            dw LevelMultiplier.THREE
            dw LevelMultiplier.FOUR
            dw LevelMultiplier.FIVE
        end
    end # end namespace
end # end namespace
