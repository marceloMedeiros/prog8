%import c64utils
%option enable_floats

~ main {

    const uword width = 40
    const uword height = 25

    sub start()  {

        float t
        ubyte color

        while true {
            float x = sin(t)
            float y = cos(t*1.1356)
            ubyte xx=screenx(x)
            ubyte yy=screeny(y)

            c64.COLOR = color
            c64scr.PLOT(xx,yy)
            c64.CHROUT('Q')     ;  shift-q = filled circle
            ; the 3 lines above can be replaced by:  c64scr.setchrclr(xx, yy, 81, color)

            t  += 0.08
            color++
        }
    }

    sub screenx(float x) -> ubyte {
        return b2ub(fintb(x * flt(width)/2.2) + width//2)
    }
    sub screeny(float y) -> ubyte {
        return b2ub(fintb(y * flt(height)/2.2) + height//2)
    }
}