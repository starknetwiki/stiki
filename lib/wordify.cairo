
%builtins output range_check
from starkware.cairo.common.math import unsigned_div_rem,assert_lt_felt,assert_le_felt
from starkware.cairo.common.math_cmp import is_le_felt,is_in_range
from starkware.cairo.common.pow import pow
from starkware.cairo.common.memset import memset
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc
from myers import edit_distance


# takes a byte array encoded as 128 bit words and segments text into shortstring dictionary words
# will fail on words bigger than 31 chars
func wordify{range_check_ptr}(words128_len, words128 : felt*,bytes) -> (words_len, words : felt*):
    alloc_locals
    let (local chars : felt*) = alloc()
    # split 128bit words into a char array writing to char
    charify(words128_len,words128,bytes,chars)
    let (local words : felt*) = alloc()
    let (words_len) = wordify_rec(bytes,chars,0,words,0,0)
    return (words_len,words)
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

func wordify_rec{range_check_ptr}(
        chars_remaining, chars : felt*, words_len, words : felt*, word_buffer, i
    ) -> (words_len):
    alloc_locals
    if chars_remaining == 0:
        return (words_len)
    end
    let (is_upper) = is_in_range([chars],65,91)
    let (is_lower) = is_in_range([chars],97,123)
    local is_alpha = is_upper + is_lower
    let (b) = is_le_felt(16,i)
    if b == 1:
        if is_alpha == 1:
            return wordify_rec(chars_remaining-1,chars+1,words_len,words,0,i+1)
        else:
            assert [words] = 0
            if [chars] == 32:
                return wordify_rec(chars_remaining-1,chars+1,words_len+1,words+1,0,0)
            else:
                assert [words + 1] = [chars]
                return wordify_rec(chars_remaining-1,chars+1,words_len+2,words+2,0,0)
            end
        end
    else:
        if is_alpha == 1:
            return wordify_rec(
                chars_remaining-1,
                chars+1,
                words_len,
                words,
                word_buffer*2**8 + [chars],
                i+1)
        else:
            if word_buffer == 0:
                assert [words] = [chars]
                return wordify_rec(chars_remaining-1,chars+1,words_len+1,words+1,0,0)
            else:
                assert [words] = word_buffer
                assert [words + 1] = [chars]
                return wordify_rec(chars_remaining-1,chars+1,words_len+2,words+2,0,0)
            end
            
        end
    end
end




# takes a byte array encoded as a 128 bit words and split each word into chars and write to buffer
func charify{range_check_ptr}(words_len, words : felt*, bytes, buffer : felt*):
    charify_rec(words_len,words,bytes,buffer)
    return ()
end

func charify_rec{range_check_ptr}(words_len, words : felt*, bytes, buffer : felt*):
    if words_len == 0:
        return ()
    end
    if words_len == 1:
        let (_,trail) = unsigned_div_rem(bytes,16)
        if trail == 0:
            charify_word([words],buffer)
        else:
            let (shift) = pow(2**8,16-trail)
            charify_word([words]*shift,buffer)
        end
        return ()
    else:
        charify_word([words],buffer)
        return charify_rec(words_len - 1, words + 1, bytes, buffer + 16)
    end
end
# takes a byte array encoded as a 128 bit word and split into chars and write to buffer
func charify_word{range_check_ptr}(word : felt, buffer : felt*):
    alloc_locals
    const BYTE = 2**8
    let (remaining,char) = unsigned_div_rem(word,BYTE)
    assert buffer[15] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[14] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[13] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[12] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[11] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[10] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[9] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[8] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[7] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[6] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[5] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[4] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[3] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[2] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[1] = char
    let (remaining,char) = unsigned_div_rem(remaining,BYTE)
    assert buffer[0] = char
    return ()
end
# Consume characters until you reach a special character or run of buffer, then return short string
# func consume_word(bytes_len,bytes : felt*, chars : felt*,i,buffer_len : felt,buffer : felt*) -> (word : felt):
#     if buffer_len
# end

func serialize_words{output_ptr : felt*}(words_len : felt, words : felt*):
    tempvar output_ptr = output_ptr
    tempvar i = 0
    loop:
    if i == words_len:
        return ()
    else:
        serialize_word(words[i])
        tempvar output_ptr = output_ptr
        tempvar i = i + 1
        jmp loop
    end
end

func main{output_ptr : felt*,range_check_ptr}():
    alloc_locals
    let (local string1 : felt*) = alloc()
    memset(string1,'I dont know why ',20)
    let (local string2 : felt*) = alloc()
    memset(string2,'Do you know why ',20)
    let (local words1_len,local words1) = wordify(20,string1,320)
    let (local words2_len,local words2) = wordify(20,string2,320)
    %{
        for i in range(ids.words1_len):
            print(memory[ids.words1+i].to_bytes(16,'big').strip(b'\x00'))
        for i in range(ids.words2_len):
            print(memory[ids.words2+i].to_bytes(16,'big').strip(b'\x00'))
    %}
    let (x) = edit_distance(words1_len,words1,words2_len,words2)
    serialize_word(x)
    return ()
end