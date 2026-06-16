#!/usr/bin/env python3
def sprdelay(active):
    return sum(map(int, list((bin(active)[2:] + '00').replace('100', '5').replace('10', '4').replace('1','2'))))
 
print(f"{'Dec':>3}  {'Binary':10}  {'Cycles':>6}  Sprites active")
print("-" * 50)
for i in range(256):
    binary   = bin(i)[2:].zfill(8)
    cycles   = sprdelay(i)
    # Show which sprite numbers are active (bit 0 = sprite 0)
    active   = [str(b) for b in range(8) if i & (1 << b)]
    sprites  = ', '.join(active) if active else 'none'
    print(f"{i:3d}  0b{binary}  {cycles:2d}       {sprites}")
