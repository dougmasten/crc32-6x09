CRC32-6x09
==========

## Description

An Hitachi 6309 library for calculating a CRC32 value.

## Example

```
crc_value rmb 4

    include crc32.asm

    ldu #buffer
    ldy #buffer_len
    jsr crc32
    stq crc_value
```

## TODO

Implement Motorola 6809 version

## License
See [LICENSE.md](LICENSE.md)
