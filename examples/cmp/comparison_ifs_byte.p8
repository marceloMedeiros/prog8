%import textio
%zeropage basicsafe

; Note: this program is compatible with C64 and CX16.

main {

    sub start()  {

        byte v1
        byte v2

        v1 = 100
        v2 = 127
        if v1==v2
            txt.print("error in 100==127!\n")
        else
            txt.print("ok: 100 not == 127\n")

        if v1!=v2
            txt.print("ok: 100 != 127\n")
        else
            txt.print("error in 100!=127!\n")

        if v1<v2
            txt.print("ok: 100 < 127\n")
        else
            txt.print("error in 100<127!\n")

        if v1<=v2
            txt.print("ok: 100 <= 127\n")
        else
            txt.print("error in 100<=127!\n")

        if v1>v2
            txt.print("error in 100>127!\n")
        else
            txt.print("ok: 100 is not >127\n")

        if v1>=v2
            txt.print("error in 100>=127!\n")
        else
            txt.print("ok: 100 is not >=127\n")


        v1 = 125
        v2 = 22
        if v1==v2
            txt.print("error in 125==22!\n")
        else
            txt.print("ok: 125 not == 22\n")

        if v1!=v2
            txt.print("ok: 125 != 22\n")
        else
            txt.print("error in 125!=22!\n")

        if v1<v2
            txt.print("error in 125<22!\n")
        else
            txt.print("ok: 125 is not < 22\n")

        if v1<=v2
            txt.print("error in 125<=22!\n")
        else
            txt.print("ok: 125 is not <= 22\n")

        if v1>v2
            txt.print("ok: 125 > 22\n")
        else
            txt.print("error in 125>22!\n")

        if v1>=v2
            txt.print("ok: 125 >= 22\n")
        else
            txt.print("error in 125>=22!\n")

        v1 = 22
        v2 = 22
        if v1==v2
            txt.print("ok: 22 == 22\n")
        else
            txt.print("error in 22==22!\n")

        if v1!=v2
            txt.print("error in 22!=22!\n")
        else
            txt.print("ok: 22 is not != 22\n")

        if v1<v2
            txt.print("error in 22<22!\n")
        else
            txt.print("ok: 22 is not < 22\n")

        if v1<=v2
            txt.print("ok: 22 <= 22\n")
        else
            txt.print("error in 22<=22!\n")

        if v1>v2
            txt.print("error in 22>22!\n")
        else
            txt.print("ok: 22 is not > 22\n")

        if v1>=v2
            txt.print("ok: 22 >= 22\n")
        else
            txt.print("error in 22>=22!\n")
    }
}
