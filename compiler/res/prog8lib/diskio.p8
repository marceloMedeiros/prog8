%import textio
%import syslib

; Note: this code is compatible with C64 and CX16.

diskio {


    sub directory(ubyte drivenumber) -> ubyte {
        ; -- Shows the directory contents of disk drive 8-11 (provide as argument). Returns success flag.

        c64.SETNAM(1, "$")
        c64.SETLFS(1, drivenumber, 0)
        void c64.OPEN()          ; open 1,8,0,"$"
        if_cs
            goto io_error
        void c64.CHKIN(1)        ; use #1 as input channel
        if_cs
            goto io_error

        repeat 4 {
            void c64.CHRIN()     ; skip the 4 prologue bytes
        }

        ; while not key pressed / EOF encountered, read data.
        ubyte status = c64.READST()
        while not status {
            ubyte low = c64.CHRIN()
            ubyte high = c64.CHRIN()
            txt.print_uw(mkword(high, low))
            txt.chrout(' ')
            ubyte @zp char
            do {
                char = c64.CHRIN()
                txt.chrout(char)
            } until char==0
            txt.chrout('\n')
            void c64.CHRIN()     ; skip 2 bytes
            void c64.CHRIN()
            status = c64.READST()
            void c64.STOP()
            if_nz
                break
        }

io_error:
        status = c64.READST()
        c64.CLRCHN()        ; restore default i/o devices
        c64.CLOSE(1)

        if status and status != 64 {            ; 64=end of file
            txt.print("\ni/o error, status: ")
            txt.print_ub(status)
            txt.chrout('\n')
            return false
        }

        return true
    }


    ; internal variables for the iterative file lister
    ubyte list_suffixmatch
    ubyte list_in_progress = false
    ubyte list_pattern_size
    ubyte list_skip_disk_name
    uword list_pattern
    uword list_blocks
    str   list_filename = "????????????????"

    sub lf_start_list(ubyte drivenumber, uword pattern, ubyte suffixmatch) -> ubyte {
        ; -- start an iterative file listing with optional prefix or suffix name matching.
        lf_end_list()
        list_pattern = pattern
        list_suffixmatch = suffixmatch
        list_skip_disk_name = true
        list_in_progress = true
        if pattern==0
            list_pattern_size = 0
        else
            list_pattern_size = strlen(pattern)

        c64.SETNAM(1, "$")
        c64.SETLFS(1, drivenumber, 0)
        void c64.OPEN()          ; open 1,8,0,"$"
        if_cs
            goto io_error
        void c64.CHKIN(1)        ; use #1 as input channel
        if_cs
            goto io_error

        repeat 4 {
            void c64.CHRIN()     ; skip the 4 prologue bytes
        }

        if c64.READST()==0
            return true

io_error:
        lf_end_list()
        return false
    }

    sub lf_next_entry() -> ubyte {
        ; -- retrieve the next entry from an iterative file listing session.
        ;    results will be found in list_blocks and list_filename.
        ;    if it returns false though, there are no more entries (or an error occurred).

        if not list_in_progress
            return false

        while not c64.READST() {
            uword nameptr = &list_filename
            ubyte blocks_lsb = c64.CHRIN()
            ubyte blocks_msb = c64.CHRIN()
            list_blocks = mkword(blocks_msb, blocks_lsb)

            ; read until the filename starts after the first "
            while c64.CHRIN()!='\"'  {
                if c64.READST()
                    goto close_end
            }

            ; read the filename
            repeat {
                ubyte char = c64.CHRIN()
                if_z
                    break
                if char=='\"'
                    break
                @(nameptr) = char
                nameptr++
            }

            @(nameptr) = 0

            while c64.CHRIN() {
                ; read the rest of the entry until the end
            }

            void c64.CHRIN()     ; skip 2 bytes
            void c64.CHRIN()

            if not list_skip_disk_name {
                if list_pattern_size {
                    ; do filename matching
                    if list_suffixmatch
                        rightstr(list_filename, filename, list_pattern_size)
                    else
                        leftstr(list_filename, filename, list_pattern_size)
                    if strcmp(filename, list_pattern)==0
                        return true
                } else
                    return true
            }
            list_skip_disk_name = false
        }

close_end:
        lf_end_list()
        return false
    }

    sub lf_end_list() {
        ; -- end an iterative file listing session (close channels).
        if list_in_progress {
            c64.CLRCHN()
            c64.CLOSE(1)
            list_in_progress = false
        }
    }


    sub status(ubyte drivenumber) {
        ; -- display the disk drive's current status message
        c64.SETNAM(0, filename)
        c64.SETLFS(15, drivenumber, 15)
        void c64.OPEN()          ; open 15,8,15
        if_cs
            goto io_error
        void c64.CHKIN(15)        ; use #15 as input channel
        if_cs
            goto io_error

        while not c64.READST()
            txt.chrout(c64.CHRIN())

io_error:
        c64.CLRCHN()        ; restore default i/o devices
        c64.CLOSE(15)
    }


    sub save(ubyte drivenumber, uword filenameptr, uword address, uword size) -> ubyte {
        c64.SETNAM(strlen(filenameptr), filenameptr)
        c64.SETLFS(1, drivenumber, 0)
        uword end_address = address + size

        %asm {{
            lda  address
            sta  P8ZP_SCRATCH_W1
            lda  address+1
            sta  P8ZP_SCRATCH_W1+1
            stx  P8ZP_SCRATCH_REG
            lda  #<P8ZP_SCRATCH_W1
            ldx  end_address
            ldy  end_address+1
            jsr  c64.SAVE
            php
            ldx  P8ZP_SCRATCH_REG
            plp
        }}

        ubyte result=0
        if_cc
            result = c64.READST()==0

        c64.CLRCHN()
        c64.CLOSE(1)

        return result
    }

    sub load(ubyte drivenumber, uword filenameptr, uword address_override) -> uword {
        c64.SETNAM(strlen(filenameptr), filenameptr)
        ubyte secondary = 1
        uword end_of_load = 0
        if address_override
            secondary = 0
        c64.SETLFS(1, drivenumber, secondary)
        %asm {{
            stx  P8ZP_SCRATCH_REG
            lda  #0
            ldx  address_override
            ldy  address_override+1
            jsr  c64.LOAD
            bcs  +
            stx  end_of_load
            sty  end_of_load+1
+           ldx  P8ZP_SCRATCH_REG
        }}

        c64.CLRCHN()
        c64.CLOSE(1)

        if end_of_load
            return end_of_load - address_override

        return 0
    }


    str filename = "0:??????????????????????????????????????"

    sub delete(ubyte drivenumber, uword filenameptr) {
        ; -- delete a file on the drive
        ubyte flen = strlen(filenameptr)
        filename[0] = 's'
        filename[1] = ':'
        memcopy(filenameptr, &filename+2, flen+1)
        c64.SETNAM(flen+2, filename)
        c64.SETLFS(1, drivenumber, 15)
        void c64.OPEN()
        c64.CLRCHN()
        c64.CLOSE(1)
    }

    sub rename(ubyte drivenumber, uword oldfileptr, uword newfileptr) {
        ; -- rename a file on the drive
        ubyte flen_old = strlen(oldfileptr)
        ubyte flen_new = strlen(newfileptr)
        filename[0] = 'r'
        filename[1] = ':'
        memcopy(newfileptr, &filename+2, flen_new)
        filename[flen_new+2] = '='
        memcopy(oldfileptr, &filename+3+flen_new, flen_old+1)
        c64.SETNAM(3+flen_new+flen_old, filename)
        c64.SETLFS(1, drivenumber, 15)
        void c64.OPEN()
        c64.CLRCHN()
        c64.CLOSE(1)
    }
}
