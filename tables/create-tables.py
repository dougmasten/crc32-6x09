#!/usr/bin/env python
# Create lookup tables for CRC32

# Polynoms in reversed notation
POLYNOMS = {
    'crc32ieee': 0xedb88320,   # 802.3
    'crc32c': 0x82F63B78,      # Castagnoli
    'crc32k': 0xeb31d82e,      # Koopman
    'crc32q': 0xd5828281       # Q
}


def build_table_16(poly):
    table = []
    for i in range(0,256,16):
        crc = i
        for j in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
        table.append(crc)
    return table


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


def output_table(table, k, version):
    poly = POLYNOMS[k]
    filename = k + '-table' + str(version) + '.asm'
    print('File created - %s' % filename)
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
    poly = POLYNOMS[k]

    version = 16
    table = build_table_16(poly)
    output_table(table, k, version)

    version = 32
    table = build_table_32(poly)
    output_table(table, k, version)


    version = 256
    table = build_table_256(poly)
    output_table(table, k, version)
