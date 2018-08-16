package il65tests

import il65.ast.DataType
import il65.ast.VarDecl
import il65.ast.VarDeclType
import il65.compiler.*
import org.hamcrest.MatcherAssert.assertThat
import org.hamcrest.Matchers.equalTo
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith


@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class TestCompiler {
    @Test
    fun testToHex() {
        assertEquals("0", 0.toHex())
        assertEquals("1", 1.toHex())
        assertEquals("1", 1.234.toHex())
        assertEquals("10", 10.toHex())
        assertEquals("10", 10.99.toHex())
        assertEquals("15", 15.toHex())
        assertEquals("$10", 16.toHex())
        assertEquals("\$ff", 255.toHex())
        assertEquals("$0100", 256.toHex())
        assertEquals("$4e5c", 20060.toHex())
        assertEquals("\$ffff", 65535.toHex())
        assertEquals("\$ffff", 65535L.toHex())
        assertFailsWith<CompilerException> { 65536.toHex()  }
        assertFailsWith<CompilerException> { (-1).toHex()  }
        assertFailsWith<CompilerException> { (-1.99).toHex()  }
    }


    @Test
    fun testFloatToMflpt5() {
        assertThat((0).toMflpt5(), equalTo(shortArrayOf(0x00, 0x00, 0x00, 0x00, 0x00)))
        assertThat((3.141592653).toMflpt5(), equalTo(shortArrayOf(0x82, 0x49, 0x0F, 0xDA, 0xA1)))
        assertThat((3.141592653589793).toMflpt5(), equalTo(shortArrayOf(0x82, 0x49, 0x0F, 0xDA, 0xA2)))
        assertThat((-32768).toMflpt5(), equalTo(shortArrayOf(0x90, 0x80, 0x00, 0x00, 0x00)))
        assertThat((1).toMflpt5(), equalTo(shortArrayOf(0x81, 0x00, 0x00, 0x00, 0x00)))
        assertThat((0.7071067812).toMflpt5(), equalTo(shortArrayOf(0x80, 0x35, 0x04, 0xF3, 0x34)))
        assertThat((0.7071067811865476).toMflpt5(), equalTo(shortArrayOf(0x80, 0x35, 0x04, 0xF3, 0x33)))
        assertThat((1.4142135624).toMflpt5(), equalTo(shortArrayOf(0x81, 0x35, 0x04, 0xF3, 0x34)))
        assertThat((1.4142135623730951).toMflpt5(), equalTo(shortArrayOf(0x81, 0x35, 0x04, 0xF3, 0x33)))
        assertThat((-.5).toMflpt5(), equalTo(shortArrayOf(0x80, 0x80, 0x00, 0x00, 0x00)))
        assertThat((0.69314718061).toMflpt5(), equalTo(shortArrayOf(0x80, 0x31, 0x72, 0x17, 0xF8)))
        assertThat((0.6931471805599453).toMflpt5(), equalTo(shortArrayOf(0x80, 0x31, 0x72, 0x17, 0xF7)))
        assertThat((10).toMflpt5(), equalTo(shortArrayOf(0x84, 0x20, 0x00, 0x00, 0x00)))
        assertThat((1000000000).toMflpt5(), equalTo(shortArrayOf(0x9E, 0x6E, 0x6B, 0x28, 0x00)))
        assertThat((.5).toMflpt5(), equalTo(shortArrayOf(0x80, 0x00, 0x00, 0x00, 0x00)))
        assertThat((1.4426950408889634).toMflpt5(), equalTo(shortArrayOf(0x81, 0x38, 0xAA, 0x3B, 0x29)))
        assertThat((1.5707963267948966).toMflpt5(), equalTo(shortArrayOf(0x81, 0x49, 0x0F, 0xDA, 0xA2)))
        assertThat((6.283185307179586).toMflpt5(), equalTo(shortArrayOf(0x83, 0x49, 0x0F, 0xDA, 0xA2)))
        assertThat((.25).toMflpt5(), equalTo(shortArrayOf(0x7F, 0x00, 0x00, 0x00, 0x00)))
    }

    @Test
    fun testFloatRange() {
        assertThat(FLOAT_MAX_POSITIVE.toMflpt5(), equalTo(shortArrayOf(0xff, 0x7f, 0xff, 0xff, 0xff)))
        assertThat(FLOAT_MAX_NEGATIVE.toMflpt5(), equalTo(shortArrayOf(0xff, 0xff, 0xff, 0xff, 0xff)))
        assertThat((1.7e-38).toMflpt5(), equalTo(shortArrayOf(0x03, 0x39, 0x1d, 0x15, 0x63)))
        assertThat((1.7e-39).toMflpt5(), equalTo(shortArrayOf(0x00, 0x00, 0x00, 0x00, 0x00)))
        assertThat((-1.7e-38).toMflpt5(), equalTo(shortArrayOf(0x03, 0xb9, 0x1d, 0x15, 0x63)))
        assertThat((-1.7e-39).toMflpt5(), equalTo(shortArrayOf(0x00, 0x00, 0x00, 0x00, 0x00)))
        assertFailsWith<CompilerException> { 1.7014118346e+38.toMflpt5() }
        assertFailsWith<CompilerException> { (-1.7014118346e+38).toMflpt5() }
        assertFailsWith<CompilerException> { 1.7014118347e+38.toMflpt5() }
        assertFailsWith<CompilerException> { (-1.7014118347e+38).toMflpt5() }
    }

    // @todo test the other way round, mflpt-bytes -> float.
}


@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class TestZeropage {
    @Test
    fun testNames() {
        val zp = Zeropage(CompilationOptions(OutputType.RAW, LauncherType.NONE, ZeropageType.COMPATIBLE, false))

        assertFailsWith<AssertionError> {
            zp.allocate(VarDecl(VarDeclType.MEMORY, DataType.BYTE, null, "", null))
        }

        zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
        zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
        zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "varname", null))
        assertFailsWith<AssertionError> {
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "varname", null))
        }
        zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "varname2", null))
    }

    @Test
    fun testZpFloatEnable() {
        val zp = Zeropage(CompilationOptions(OutputType.RAW, LauncherType.NONE, ZeropageType.FULL, false))
        assertFailsWith<CompilerException> {
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.FLOAT, null, "", null))
        }
        val zp2 = Zeropage(CompilationOptions(OutputType.RAW, LauncherType.NONE, ZeropageType.FULL, true))
        zp2.allocate(VarDecl(VarDeclType.VAR, DataType.FLOAT, null, "", null))
    }

    @Test
    fun testCompatibleAllocation() {
        val zp = Zeropage(CompilationOptions(OutputType.RAW, LauncherType.NONE, ZeropageType.COMPATIBLE, true))
        assert(zp.available() == 9)
        assertFailsWith<CompilerException> {
            // in regular zp there aren't 5 sequential bytes free
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.FLOAT, null, "", null))
        }
        for (i in 0 until zp.available()) {
            val loc = zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
            assert(loc > 0)
        }
        assert(zp.available() == 0)
        assertFailsWith<CompilerException> {
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
        }
        assertFailsWith<CompilerException> {
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.WORD, null, "", null))
        }
    }

    @Test
    fun testFullAllocation() {
        val zp = Zeropage(CompilationOptions(OutputType.RAW, LauncherType.NONE, ZeropageType.FULL, true))
        assert(zp.available() == 239)
        val loc = zp.allocate(VarDecl(VarDeclType.VAR, DataType.FLOAT, null, "", null))
        assert(loc > 3)
        assert(!zp.free.contains(loc))
        val num = zp.available() / 5
        val rest = zp.available() % 5

        for(i in 0..num-4) {
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.FLOAT, null, "", null))
        }
        assert(zp.available() == 19)

        assertFailsWith<CompilerException> {
            // can't allocate because no more sequential bytes, only fragmented
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.FLOAT, null, "", null))
        }

        for(i in 0..13) {
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
        }
        zp.allocate(VarDecl(VarDeclType.VAR, DataType.WORD, null, "", null))
        zp.allocate(VarDecl(VarDeclType.VAR, DataType.WORD, null, "", null))

        assert(zp.available() == 1)
        zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
        assertFailsWith<CompilerException> {
            // no more space
            zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null))
        }
    }

    @Test
    fun testEfficientAllocation() {
        //  free = [0x04, 0x05, 0x06, 0x2a, 0x52, 0xf7, 0xf8, 0xf9, 0xfa]
        val zp = Zeropage(CompilationOptions(OutputType.RAW, LauncherType.NONE, ZeropageType.COMPATIBLE, true))
        assert(zp.available()==9)
        assert(0x2a == zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null)))
        assert(0x52 == zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null)))
        assert(0x04 == zp.allocate(VarDecl(VarDeclType.VAR, DataType.WORD, null, "", null)))
        assert(0xf7 == zp.allocate(VarDecl(VarDeclType.VAR, DataType.WORD, null, "", null)))
        assert(0x06 == zp.allocate(VarDecl(VarDeclType.VAR, DataType.BYTE, null, "", null)))
        assert(0xf9 == zp.allocate(VarDecl(VarDeclType.VAR, DataType.WORD, null, "", null)))
        assert(zp.available()==0)
    }
}