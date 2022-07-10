from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.default_dict import (
    default_dict_new, default_dict_finalize)
from starkware.cairo.common.dict import (
    dict_write, dict_read, dict_update)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_not_zero,is_le_felt
from starkware.cairo.common.math import (
    assert_lt_felt,assert_le_felt,signed_div_rem)

struct Globals:
    member old_str : felt*
    member new_str : felt*
    member N : felt   
    member M : felt
    member MAX : felt
    member V_len : felt
end


func is_lt_felt{range_check_ptr}(a,b) -> (res : felt):
    %{ memory[ap] = 0 if (ids.a % PRIME) < (ids.b % PRIME) else 1 %}
    jmp not_le if [ap] != 0; ap++
    assert_lt_felt(a, b)
    return (res=1)
    not_le:
    assert_le_felt(b, a)
    return (res=0)
end

func edit_distance{range_check_ptr}(
        old_str_len : felt,
        old_str : felt*,
        new_str_len : felt,
        new_str : felt*
    ) -> (res : felt):
    alloc_locals
    let N = old_str_len
    let M = new_str_len
    let MAX = N + M
    let dict_len = 2 * MAX + 2

    let (local dict_ptr : DictAccess*) = default_dict_new(default_value=0)
    default_dict_finalize(
        dict_accesses_start=dict_ptr,
        dict_accesses_end=dict_ptr,
        default_value=0)

    tempvar globals : Globals* = new Globals(old_str,new_str,N,M,MAX,dict_len)
    with dict_ptr:
        with globals:
            let (res) = edit_distance_rec(0,0)
            return (res)
        end
    end
end

func edit_distance_rec{
        range_check_ptr,
        dict_ptr : DictAccess*,
        globals : Globals*
    }(D,k) -> (res : felt):
    alloc_locals
    let bound = 2**127
    let old_str = globals.old_str
    let new_str = globals.new_str
    let N = globals.N
    let M = globals.M
    let MAX = globals.MAX
    let V_len = globals.V_len

    let (_,local idx) = signed_div_rem(k,V_len,bound)
    let (_,local idx_minus_1) = signed_div_rem(k - 1,V_len,bound)
    let (_,local idx_plus_1) = signed_div_rem(k + 1,V_len,bound)
    let (V_k_minus_1) = dict_read(idx_minus_1)
    let (V_k_plus_1) = dict_read(idx_plus_1)
    if k == - D:
        tempvar x = V_k_plus_1
        tempvar range_check_ptr = range_check_ptr
    else:
        let (b) = is_not_zero(k - D)
        if b == 1:
            let (b) = is_lt_felt(V_k_minus_1,V_k_plus_1)
            if b == 1:
                tempvar x = V_k_plus_1
                tempvar range_check_ptr = range_check_ptr
            else:
                tempvar x = V_k_minus_1 + 1
                tempvar range_check_ptr = range_check_ptr
            end
        else:
            tempvar x = V_k_minus_1 + 1
            tempvar range_check_ptr = range_check_ptr
        end
    end
    tempvar y = x - k
    let (x,y) = edit_distance_rec2(x,y)
    dict_write(idx,x)
    let (local b1) = is_le_felt(N,x)
    let (b2) = is_le_felt(M,y)
    tempvar b = b1 * b2
    if b == 1:
        return (D)
    end
    tempvar range_check_ptr = range_check_ptr

    if k == D:
        return edit_distance_rec(
            D=D + 1,
            k=-(D + 1)
        )
    else:
        return edit_distance_rec(
            D=D,
            k=k + 2
        )
    end
end

func edit_distance_rec2{range_check_ptr,globals : Globals*}(x : felt,y : felt) -> (x : felt, y : felt):
    alloc_locals
    let old_str = globals.old_str
    let new_str = globals.new_str
    let N = globals.N
    let M = globals.M

    let (b1) = is_lt_felt(x,N)
    let (b2) = is_lt_felt(y,M)
    tempvar b = b1 * b2
    if b == 1:
        if old_str[x] == new_str[y]:
            return edit_distance_rec2(x + 1,y + 1)
        end
    end
    return (x,y)
end
