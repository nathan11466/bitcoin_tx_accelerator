import hashlib

hash_vals = []

with open('./hash_in.txt', 'rb') as f_in:
    for line in f_in:
        byte_str = line.strip() # no need to decode/encode for bytes
        hash = hashlib.sha256(hashlib.sha256(byte_str).digest()).hexdigest() # use digest() instead of hexdigest() for the inner hash
        hash_vals.append(hash) # store hash value

with open('./simu_out_std.txt', 'w') as f_out:
    f_out.writelines('%s\n' % h for h in hash_vals)
