bnd = open("scroll_bnd.bin", "rb").read()
top = open("scroll_top.bin", "rb").read()

print(f"Text length: {len(top)}")
for i in range(190, len(top)):
    print(f"  [{i:3d}] bnd={bnd[i]}  top=${top[i]:02x}")
