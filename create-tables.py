#!/usr/bin/env python
# Create lookup tables for CRC32

# Polynoms in reversed notation
POLYNOMS = {
    'crc32ieee': 0xedb88320,   # 802.3
    'crc32c': 0x82F63B78,      # Castagnoli
    'crc32k': 0xeb31d82e,      # Koopman
    'crc32q': 0xd5828281       # Q
}


def build_table_32(poly):
    table = []
    for i in range(16):
        crc = i
        for j in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
        table.append(crc)

    for i in range(16):
        crc = i << 4
        for j in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
        table.append(crc)
    return table


def build_table_256(poly):
    table = []
    for i in range(256):
        crc = i
        for j in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
        table.append(crc)
    return table


def output_table(filename, table, poly):
    with open(filename, 'w') as f:
        f.write('; %s\n' % filename)
        f.write('; Polynomial - $%x\n' % poly)
        f.write('\n')

        for i in range(0, len(table), 8):
            f.write('  fqb ${:08x},${:08x},${:08x},${:08x},'
                    '${:08x},${:08x},${:08x},${:08x}\n'
                    .format(table[i], table[i + 1], table[i + 2], table[i + 3],
                     table[i + 4], table[i + 5], table[i + 6], table[i + 7]))


for k in POLYNOMS:
    filename = k + '-table.asm'
    poly = POLYNOMS[k]
    table = build_table_256(poly)
    output_table(filename, table, poly)
    print('File created - %s' % filename)
