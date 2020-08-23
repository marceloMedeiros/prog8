%import c64lib
%import c64utils
%import c64graphics


main {

    const uword width = 255
    const uword height = 200

    ; vertices
    word[] xcoor = [ -100, -100, -100, -100,  100,  100,  100, 100 ]
    word[] ycoor = [ -100, -100,  100,  100, -100, -100,  100, 100 ]
    word[] zcoor = [ -100,  100, -100,  100, -100,  100, -100, 100 ]

    ; storage for rotated coordinates
    word[len(xcoor)] rotatedx
    word[len(ycoor)] rotatedy
    word[len(zcoor)] rotatedz

    ; edges
    ubyte[] edgesFrom = [ 0, 2, 6, 4, 1, 3, 7, 5, 0, 2, 6, 4]
    ubyte[] edgesTo = [ 2, 6, 4, 0, 3, 7, 5, 1, 1, 3, 7, 5]


    sub start()  {
        uword anglex
        uword angley
        uword anglez

        graphics.enable_bitmap_mode()


        repeat {
            rotate_vertices(msb(anglex), msb(angley), msb(anglez))
            graphics.clear_screen()
            draw_lines()
            anglex-=500
            angley+=217
            anglez+=452

            while c64.RASTER!=255 {
            }
            while c64.RASTER!=254 {
            }
        }
    }

    sub rotate_vertices(ubyte ax, ubyte ay, ubyte az) {
        ; rotate around origin (0,0,0)

        ; set up the 3d rotation matrix values
        word wcosa = cos8(ax)
        word wsina = sin8(ax)
        word wcosb = cos8(ay)
        word wsinb = sin8(ay)
        word wcosc = cos8(az)
        word wsinc = sin8(az)

        word wcosa_sinb = wcosa*wsinb / 128
        word wsina_sinb = wsina*wsinb / 128

        word Axx = wcosa*wcosb / 128
        word Axy = (wcosa_sinb*wsinc - wsina*wcosc) / 128
        word Axz = (wcosa_sinb*wcosc + wsina*wsinc) / 128
        word Ayx = wsina*wcosb / 128
        word Ayy = (wsina_sinb*wsinc + wcosa*wcosc) / 128
        word Ayz = (wsina_sinb*wcosc - wcosa*wsinc) / 128
        word Azx = -wsinb
        word Azy = wcosb*wsinc / 128
        word Azz = wcosb*wcosc / 128

        ubyte i
        for i in 0 to len(xcoor)-1 {
            ; don't normalize by dividing by 128, instead keep some precision for perspective calc later
            rotatedx[i] = (Axx*xcoor[i] + Axy*ycoor[i] + Axz*zcoor[i])
            rotatedy[i] = (Ayx*xcoor[i] + Ayy*ycoor[i] + Ayz*zcoor[i])
            rotatedz[i] = (Azx*xcoor[i] + Azy*ycoor[i] + Azz*zcoor[i])
        }
    }

    sub draw_lines() {
        ubyte i
        for i in len(edgesFrom) -1 downto 0 {
            ubyte vFrom = edgesFrom[i]
            ubyte vTo = edgesTo[i]
            word persp1 = 256 + rotatedz[vFrom]/256
            word persp2 = 256 + rotatedz[vTo]/256
            graphics.line(rotatedx[vFrom] / persp1 + 160.w as uword,
                          rotatedy[vFrom] / persp1 + 100 as ubyte,
                          rotatedx[vTo] / persp2 + 160.w as uword,
                          rotatedy[vTo] / persp2 + 100 as ubyte)
        }
    }
}