from enum import IntEnum


class AddrMode(IntEnum):
    Imp = 1,
    Acc = 2,
    Imm = 3,
    Zp = 4,
    ZpX = 5,
    ZpY = 6,
    Rel = 7,
    Abs = 8,
    AbsX = 9,
    AbsY = 10,
    Ind = 11,
    IzX = 12,
    IzY = 13,
    Zpr = 14,
    Izp = 15,
    IaX = 16


Instructions = (
    (0x00, "brk", AddrMode.Imp),
    (0x01, "ora", AddrMode.IzX),
    (0x02, "nop", AddrMode.Imm),
    (0x03, "nop", AddrMode.Imp),
    (0x04, "tsb", AddrMode.Zp),
    (0x05, "ora", AddrMode.Zp),
    (0x06, "asl", AddrMode.Zp),
    (0x07, "rmb0", AddrMode.Zp),
    (0x08, "php", AddrMode.Imp),
    (0x09, "ora", AddrMode.Imm),
    (0x0a, "asl", AddrMode.Acc),
    (0x0b, "nop", AddrMode.Imp),
    (0x0c, "tsb", AddrMode.Abs),
    (0x0d, "ora", AddrMode.Abs),
    (0x0e, "asl", AddrMode.Abs),
    (0x0f, "bbr0", AddrMode.Zpr),
    (0x10, "bpl", AddrMode.Rel),
    (0x11, "ora", AddrMode.IzY),
    (0x12, "ora", AddrMode.Izp),
    (0x13, "nop", AddrMode.Imp),
    (0x14, "trb", AddrMode.Zp),
    (0x15, "ora", AddrMode.ZpX),
    (0x16, "asl", AddrMode.ZpX),
    (0x17, "rmb1", AddrMode.Zp),
    (0x18, "clc", AddrMode.Imp),
    (0x19, "ora", AddrMode.AbsY),
    (0x1a, "inc", AddrMode.Acc),
    (0x1b, "nop", AddrMode.Imp),
    (0x1c, "trb", AddrMode.Abs),
    (0x1d, "ora", AddrMode.AbsX),
    (0x1e, "asl", AddrMode.AbsX),
    (0x1f, "bbr1", AddrMode.Zpr),
    (0x20, "jsr", AddrMode.Abs),
    (0x21, "and", AddrMode.IzX),
    (0x22, "nop", AddrMode.Imm),
    (0x23, "nop", AddrMode.Imp),
    (0x24, "bit", AddrMode.Zp),
    (0x25, "and", AddrMode.Zp),
    (0x26, "rol", AddrMode.Zp),
    (0x27, "rmb2", AddrMode.Zp),
    (0x28, "plp", AddrMode.Imp),
    (0x29, "and", AddrMode.Imm),
    (0x2a, "rol", AddrMode.Acc),
    (0x2b, "nop", AddrMode.Imp),
    (0x2c, "bit", AddrMode.Abs),
    (0x2d, "and", AddrMode.Abs),
    (0x2e, "rol", AddrMode.Abs),
    (0x2f, "bbr2", AddrMode.Zpr),
    (0x30, "bmi", AddrMode.Rel),
    (0x31, "and", AddrMode.IzY),
    (0x32, "and", AddrMode.Izp),
    (0x33, "nop", AddrMode.Imp),
    (0x34, "bit", AddrMode.ZpX),
    (0x35, "and", AddrMode.ZpX),
    (0x36, "rol", AddrMode.ZpX),
    (0x37, "rmb3", AddrMode.Zp),
    (0x38, "sec", AddrMode.Imp),
    (0x39, "and", AddrMode.AbsY),
    (0x3a, "dec", AddrMode.Acc),
    (0x3b, "nop", AddrMode.Imp),
    (0x3c, "bit", AddrMode.AbsX),
    (0x3d, "and", AddrMode.AbsX),
    (0x3e, "rol", AddrMode.AbsX),
    (0x3f, "bbr3", AddrMode.Zpr),
    (0x40, "rti", AddrMode.Imp),
    (0x41, "eor", AddrMode.IzX),
    (0x42, "nop", AddrMode.Imm),
    (0x43, "nop", AddrMode.Imp),
    (0x44, "nop", AddrMode.Zp),
    (0x45, "eor", AddrMode.Zp),
    (0x46, "lsr", AddrMode.Zp),
    (0x47, "rmb4", AddrMode.Zp),
    (0x48, "pha", AddrMode.Imp),
    (0x49, "eor", AddrMode.Imm),
    (0x4a, "lsr", AddrMode.Acc),
    (0x4b, "nop", AddrMode.Imp),
    (0x4c, "jmp", AddrMode.Abs),
    (0x4d, "eor", AddrMode.Abs),
    (0x4e, "lsr", AddrMode.Abs),
    (0x4f, "bbr4", AddrMode.Zpr),
    (0x50, "bvc", AddrMode.Rel),
    (0x51, "eor", AddrMode.IzY),
    (0x52, "eor", AddrMode.Izp),
    (0x53, "nop", AddrMode.Imp),
    (0x54, "nop", AddrMode.ZpX),
    (0x55, "eor", AddrMode.ZpX),
    (0x56, "lsr", AddrMode.ZpX),
    (0x57, "rmb5", AddrMode.Zp),
    (0x58, "cli", AddrMode.Imp),
    (0x59, "eor", AddrMode.AbsY),
    (0x5a, "phy", AddrMode.Imp),
    (0x5b, "nop", AddrMode.Imp),
    (0x5c, "nop", AddrMode.Abs),
    (0x5d, "eor", AddrMode.AbsX),
    (0x5e, "lsr", AddrMode.AbsX),
    (0x5f, "bbr5", AddrMode.Zpr),
    (0x60, "rts", AddrMode.Imp),
    (0x61, "adc", AddrMode.IzX),
    (0x62, "nop", AddrMode.Imm),
    (0x63, "nop", AddrMode.Imp),
    (0x64, "stz", AddrMode.Zp),
    (0x65, "adc", AddrMode.Zp),
    (0x66, "ror", AddrMode.Zp),
    (0x67, "rmb6", AddrMode.Zp),
    (0x68, "pla", AddrMode.Imp),
    (0x69, "adc", AddrMode.Imm),
    (0x6a, "ror", AddrMode.Acc),
    (0x6b, "nop", AddrMode.Imp),
    (0x6c, "jmp", AddrMode.Ind),
    (0x6d, "adc", AddrMode.Abs),
    (0x6e, "ror", AddrMode.Abs),
    (0x6f, "bbr6", AddrMode.Zpr),
    (0x70, "bvs", AddrMode.Rel),
    (0x71, "adc", AddrMode.IzY),
    (0x72, "adc", AddrMode.Izp),
    (0x73, "nop", AddrMode.Imp),
    (0x74, "stz", AddrMode.ZpX),
    (0x75, "adc", AddrMode.ZpX),
    (0x76, "ror", AddrMode.ZpX),
    (0x77, "rmb7", AddrMode.Zp),
    (0x78, "sei", AddrMode.Imp),
    (0x79, "adc", AddrMode.AbsY),
    (0x7a, "ply", AddrMode.Imp),
    (0x7b, "nop", AddrMode.Imp),
    (0x7c, "jmp", AddrMode.IaX),
    (0x7d, "adc", AddrMode.AbsX),
    (0x7e, "ror", AddrMode.AbsX),
    (0x7f, "bbr7", AddrMode.Zpr),
    (0x80, "bra", AddrMode.Rel),
    (0x81, "sta", AddrMode.IzX),
    (0x82, "nop", AddrMode.Imm),
    (0x83, "nop", AddrMode.Imp),
    (0x84, "sty", AddrMode.Zp),
    (0x85, "sta", AddrMode.Zp),
    (0x86, "stx", AddrMode.Zp),
    (0x87, "smb0", AddrMode.Zp),
    (0x88, "dey", AddrMode.Imp),
    (0x89, "bit", AddrMode.Imm),
    (0x8a, "txa", AddrMode.Imp),
    (0x8b, "nop", AddrMode.Imp),
    (0x8c, "sty", AddrMode.Abs),
    (0x8d, "sta", AddrMode.Abs),
    (0x8e, "stx", AddrMode.Abs),
    (0x8f, "bbs0", AddrMode.Zpr),
    (0x90, "bcc", AddrMode.Rel),
    (0x91, "sta", AddrMode.IzY),
    (0x92, "sta", AddrMode.Izp),
    (0x93, "nop", AddrMode.Imp),
    (0x94, "sty", AddrMode.ZpX),
    (0x95, "sta", AddrMode.ZpX),
    (0x96, "stx", AddrMode.ZpY),
    (0x97, "smb1", AddrMode.Zp),
    (0x98, "tya", AddrMode.Imp),
    (0x99, "sta", AddrMode.AbsY),
    (0x9a, "txs", AddrMode.Imp),
    (0x9b, "nop", AddrMode.Imp),
    (0x9c, "stz", AddrMode.Abs),
    (0x9d, "sta", AddrMode.AbsX),
    (0x9e, "stz", AddrMode.AbsX),
    (0x9f, "bbs1", AddrMode.Zpr),
    (0xa0, "ldy", AddrMode.Imm),
    (0xa1, "lda", AddrMode.IzX),
    (0xa2, "ldx", AddrMode.Imm),
    (0xa3, "nop", AddrMode.Imp),
    (0xa4, "ldy", AddrMode.Zp),
    (0xa5, "lda", AddrMode.Zp),
    (0xa6, "ldx", AddrMode.Zp),
    (0xa7, "smb2", AddrMode.Zp),
    (0xa8, "tay", AddrMode.Imp),
    (0xa9, "lda", AddrMode.Imm),
    (0xaa, "tax", AddrMode.Imp),
    (0xab, "nop", AddrMode.Imp),
    (0xac, "ldy", AddrMode.Abs),
    (0xad, "lda", AddrMode.Abs),
    (0xae, "ldx", AddrMode.Abs),
    (0xaf, "bbs2", AddrMode.Zpr),
    (0xb0, "bcs", AddrMode.Rel),
    (0xb1, "lda", AddrMode.IzY),
    (0xb2, "lda", AddrMode.Izp),
    (0xb3, "nop", AddrMode.Imp),
    (0xb4, "ldy", AddrMode.ZpX),
    (0xb5, "lda", AddrMode.ZpX),
    (0xb6, "ldx", AddrMode.ZpY),
    (0xb7, "smb3", AddrMode.Zp),
    (0xb8, "clv", AddrMode.Imp),
    (0xb9, "lda", AddrMode.AbsY),
    (0xba, "tsx", AddrMode.Imp),
    (0xbb, "nop", AddrMode.Imp),
    (0xbc, "ldy", AddrMode.AbsX),
    (0xbd, "lda", AddrMode.AbsX),
    (0xbe, "ldx", AddrMode.AbsY),
    (0xbf, "bbs3", AddrMode.Zpr),
    (0xc0, "cpy", AddrMode.Imm),
    (0xc1, "cmp", AddrMode.IzX),
    (0xc2, "nop", AddrMode.Imm),
    (0xc3, "nop", AddrMode.Imp),
    (0xc4, "cpy", AddrMode.Zp),
    (0xc5, "cmp", AddrMode.Zp),
    (0xc6, "dec", AddrMode.Zp),
    (0xc7, "smb4", AddrMode.Zp),
    (0xc8, "iny", AddrMode.Imp),
    (0xc9, "cmp", AddrMode.Imm),
    (0xca, "dex", AddrMode.Imp),
    (0xcb, "wai", AddrMode.Imp),
    (0xcc, "cpy", AddrMode.Abs),
    (0xcd, "cmp", AddrMode.Abs),
    (0xce, "dec", AddrMode.Abs),
    (0xcf, "bbs4", AddrMode.Zpr),
    (0xd0, "bne", AddrMode.Rel),
    (0xd1, "cmp", AddrMode.IzY),
    (0xd2, "cmp", AddrMode.Izp),
    (0xd3, "nop", AddrMode.Imp),
    (0xd4, "nop", AddrMode.ZpX),
    (0xd5, "cmp", AddrMode.ZpX),
    (0xd6, "dec", AddrMode.ZpX),
    (0xd7, "smb5", AddrMode.Zp),
    (0xd8, "cld", AddrMode.Imp),
    (0xd9, "cmp", AddrMode.AbsY),
    (0xda, "phx", AddrMode.Imp),
    (0xdb, "stp", AddrMode.Imp),
    (0xdc, "nop", AddrMode.Abs),
    (0xdd, "cmp", AddrMode.AbsX),
    (0xde, "dec", AddrMode.AbsX),
    (0xdf, "bbs5", AddrMode.Zpr),
    (0xe0, "cpx", AddrMode.Imm),
    (0xe1, "sbc", AddrMode.IzX),
    (0xe2, "nop", AddrMode.Imm),
    (0xe3, "nop", AddrMode.Imp),
    (0xe4, "cpx", AddrMode.Zp),
    (0xe5, "sbc", AddrMode.Zp),
    (0xe6, "inc", AddrMode.Zp),
    (0xe7, "smb6", AddrMode.Zp),
    (0xe8, "inx", AddrMode.Imp),
    (0xe9, "sbc", AddrMode.Imm),
    (0xea, "nop", AddrMode.Imp),
    (0xeb, "nop", AddrMode.Imp),
    (0xec, "cpx", AddrMode.Abs),
    (0xed, "sbc", AddrMode.Abs),
    (0xee, "inc", AddrMode.Abs),
    (0xef, "bbs6", AddrMode.Zpr),
    (0xf0, "beq", AddrMode.Rel),
    (0xf1, "sbc", AddrMode.IzY),
    (0xf2, "sbc", AddrMode.Izp),
    (0xf3, "nop", AddrMode.Imp),
    (0xf4, "nop", AddrMode.ZpX),
    (0xf5, "sbc", AddrMode.ZpX),
    (0xf6, "inc", AddrMode.ZpX),
    (0xf7, "smb7", AddrMode.Zp),
    (0xf8, "sed", AddrMode.Imp),
    (0xf9, "sbc", AddrMode.AbsY),
    (0xfa, "plx", AddrMode.Imp),
    (0xfb, "nop", AddrMode.Imp),
    (0xfc, "nop", AddrMode.AbsX),
    (0xfd, "sbc", AddrMode.AbsX),
    (0xfe, "inc", AddrMode.AbsX),
    (0xff, "bbs7", AddrMode.Zpr)
)

InstructionsByName = {}
for ins in Instructions:
    if ins[1] not in InstructionsByName:
        InstructionsByName[ins[1]] = {ins[2]: ins[0]}
    else:
        InstructionsByName[ins[1]][ins[2]] = ins[0]

InstructionsByMode = {}
for ins in Instructions:
    if ins[2] not in InstructionsByMode:
        InstructionsByMode[ins[2]] = [(ins[1], ins[0])]
    else:
        InstructionsByMode[ins[2]].append((ins[1], ins[0]))

# build the name->modes table

print("    .cpu \"65c02\"")
print("cx16    .block")
print("    r0 = $02")
print("    .bend")
print("; addressing modes:")
for mode in AddrMode:
    print(";", mode.value, "=", mode.name)
print()

print("""

    * = $2000

        .enc "petscii"  ;define an ascii to petscii encoding
        .cdef " @", 32  ;characters
        .cdef "AZ", $c1
        .cdef "az", $41
        .cdef "[[", $5b
        .cdef "]]", $5d
        .edef "<nothing>", [];replace with no bytes
        
        
test_get_opcode:
    phx
    lda  addrmode
    sta  cx16.r0
    lda  opcode
    ldx  opcode+1
    ldy  opcode+2
    jsr  get_opcode
    ; result is pointer to i_xxx in AY  (or $0000 if not found)
    sta  $4000
    sty  $4001
    plx
    rts

opcode:
    .text  "sta",0
addrmode:
    .byte  9
    
""")

for instr in sorted(InstructionsByName.items()):
    print("i_" + instr[0] + ":\n\t.byte  ", end="")
    if len(instr[1]) == 1:
        # many instructions have just 1 addressing mode, save space for those
        info = instr[1].popitem()
        print("1,", info[0].value,",", info[1])
    else:
        print("0,0,  ", end='')
        mode_opcodes = []
        for mode in AddrMode:
            if mode in instr[1]:
                mode_opcodes.append(instr[1][mode])
            else:
                mode_opcodes.append(0)
        print(",".join(str(o) for o in mode_opcodes), end="")
        print()


mnemonics = list(sorted(set(ins[1] for ins in Instructions)))


def first_letters(mnem):
    return list(sorted(set(m[0] for m in mnemonics)))


def second_letters(firstletter):
    return list(sorted(set(m[1] for m in mnemonics if m[0] == firstletter)))


def third_letters(firstletter, secondletter):
    return list(sorted(set(m[2] for m in mnemonics if m[0] == firstletter and m[1] == secondletter)))


def fourth_letters(firstletter, secondletter, thirdletter):
    longmnem = [m for m in mnemonics if len(m) > 3]
    return list(
        sorted(set(m[3] for m in longmnem if m[0] == firstletter and m[1] == secondletter and m[2] == thirdletter)))


def make_tree():
    tree = {}
    for first in first_letters(mnemonics):
        tree[first] = {
            secondletter: {
                thirdletter: {
                    fourthletter: {}
                    for fourthletter in fourth_letters(first, secondletter, thirdletter)
                }
                for thirdletter in third_letters(first, secondletter)
            }
            for secondletter in second_letters(first)
        }
    return tree


tree = make_tree()

print("get_opcode:")
for first in tree:
    print("    cmp  #'%s'" % first)
    print("    bne  _not_%s" % first)
    for second in tree[first]:
        print("    cpx  #'%s'" % second)
        print("    bne  _not_%s%s" % (first,second))
        for third in tree[first][second]:
            print("    cpy  #'%s'" % third)
            print("    bne  _not_%s%s%s" % (first, second, third))
            if tree[first][second][third]:
                for fourth in tree[first][second][third]:
                    print("    pha")
                    print("    lda  opcode+3")
                    print("    cmp  #'%s'" % fourth)
                    print("    bne  _not_%s%s%s%s" % (first, second, third, fourth))
                    print("    pla")
                    print("    lda  #<i_%s%s%s%s" % (first, second, third, fourth))
                    print("    ldy  #>i_%s%s%s%s" % (first, second, third, fourth))
                    print("    rts")
                    print("_not_%s%s%s%s:" % (first, second, third, fourth))
                    print("    pla")
            else:
                print("    lda  #<i_%s%s%s" % (first, second, third))
                print("    ldy  #>i_%s%s%s" % (first, second, third))
                print("    rts")
            print("_not_%s%s%s:" % (first, second, third))
        print("_not_%s%s:" % (first, second))
    print("_not_%s:" % first)
print("    lda  #0")
print("    ldy  #0")
print("    rts")