bnd = open("scroll_bnd.bin", "rb").read()
top = open("scroll_top.bin", "rb").read()

for i in range(34, 44):
    print(f"  [{i:3d}] bnd={bnd[i]}  top=${top[i]:02x}")

for i in range(74, 84):
    print(f"  [{i:3d}] bnd={bnd[i]}  top=${top[i]:02x}")
