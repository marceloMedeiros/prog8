package prog8.astvm

import prog8.ast.*
import prog8.compiler.RuntimeValue
import prog8.compiler.RuntimeValueRange
import prog8.compiler.target.c64.Petscii
import java.awt.EventQueue


class VmExecutionException(msg: String?) : Exception(msg)

class VmTerminationException(msg: String?) : Exception(msg)

class VmBreakpointException : Exception("breakpoint")


class RuntimeVariables {
    fun define(scope: INameScope, name: String, initialValue: RuntimeValue) {
        val where = vars.getValue(scope)
        where[name] = initialValue
        vars[scope] = where
    }

    fun defineMemory(scope: INameScope, name: String, address: Int) {
        val where = memvars.getValue(scope)
        where[name] = address
        memvars[scope] = where
    }

    fun set(scope: INameScope, name: String, value: RuntimeValue) {
        val where = vars.getValue(scope)
        val existing = where[name]
        if(existing==null) {
            if(memvars.getValue(scope)[name]!=null)
                throw NoSuchElementException("this is a memory mapped var, not a normal var: ${scope.name}.$name")
            throw NoSuchElementException("no such runtime variable: ${scope.name}.$name")
        }
        if(existing.type!=value.type)
            throw VmExecutionException("new value is of different datatype ${value.type} expected ${existing.type} for $name")
        where[name] = value
        vars[scope] = where
    }

    fun get(scope: INameScope, name: String): RuntimeValue {
        val where = vars.getValue(scope)
        val value = where[name] ?: throw NoSuchElementException("no such runtime variable: ${scope.name}.$name")
        return value
    }

    fun getMemoryAddress(scope: INameScope, name: String): Int {
        val where = memvars.getValue(scope)
        val address = where[name] ?: throw NoSuchElementException("no such runtime memory-variable: ${scope.name}.$name")
        return address
    }

    private val vars = mutableMapOf<INameScope, MutableMap<String, RuntimeValue>>().withDefault { mutableMapOf() }
    private val memvars = mutableMapOf<INameScope, MutableMap<String, Int>>().withDefault { mutableMapOf() }
}


class AstVm(val program: Program) {
    val mem = Memory()
    var P_carry: Boolean = false
        private set
    var P_zero: Boolean = true
        private set
    var P_negative: Boolean = false
        private set
    var P_irqd: Boolean = false
        private set
    private var dialog = ScreenDialog()
    var instructionCounter = 0

    init {
        dialog.requestFocusInWindow()

        EventQueue.invokeLater {
            dialog.pack()
            dialog.isVisible = true
            dialog.start()
        }
    }

    fun run() {
        try {
            val init = VariablesCreator(runtimeVariables, program.heap)
            init.process(program)

            // initialize all global variables
            for(m in program.modules) {
                for (b in m.statements.filterIsInstance<Block>()) {
                    for (s in b.statements.filterIsInstance<Subroutine>()) {
                        if (s.name == initvarsSubName) {
                            try {
                                executeSubroutine(s, emptyList())
                            } catch (x: LoopControlReturn) {
                                // regular return
                            }
                        }
                    }
                }
            }

            val entrypoint = program.entrypoint() ?: throw VmTerminationException("no valid entrypoint found")
            try {
                executeSubroutine(entrypoint, emptyList())
            } catch (x: LoopControlReturn) {
                // regular return
            }
            println("PROGRAM EXITED!")
            dialog.title = "PROGRAM EXITED"
        } catch(bp: VmBreakpointException) {
            println("Breakpoint: execution halted. Press enter to resume.")
            readLine()
        } catch (tx: VmTerminationException) {
            println("Execution halted: ${tx.message}")
        } catch (xx: VmExecutionException) {
            println("Execution error: ${xx.message}")
            throw xx
        }
    }

    private val runtimeVariables = RuntimeVariables()
    private val functions = BuiltinFunctions()

    class LoopControlBreak: Exception()
    class LoopControlContinue: Exception()
    class LoopControlReturn(val returnvalues: List<RuntimeValue>): Exception()

    internal fun executeSubroutine(sub: Subroutine, arguments: List<RuntimeValue>): List<RuntimeValue> {
        assert(!sub.isAsmSubroutine)
        if (sub.statements.isEmpty())
            throw VmTerminationException("scope contains no statements: $sub")
        // TODO process arguments if it's a subroutine
        try {
            for (s in sub.statements) {
                executeStatement(sub, s)
            }
        } catch (r: LoopControlReturn) {
            return r.returnvalues
        }
        throw VmTerminationException("instruction pointer overflow, is a return missing? $sub")
    }

    internal fun executeAnonymousScope(scope: INameScope) {
        for (s in scope.statements) {
            executeStatement(scope, s)
        }
    }

    private fun executeStatement(sub: INameScope, stmt: IStatement) {
        val evalCtx = EvalContext(program, mem, runtimeVariables, functions, ::executeSubroutine)
        instructionCounter++
        if(instructionCounter % 100 == 0)
            Thread.sleep(1)
        when (stmt) {
            is NopStatement, is Label, is Subroutine -> {
                // do nothing, skip this instruction
            }
            is Directive -> {
                if(stmt.directive=="%breakpoint")
                    throw VmBreakpointException()
                else if(stmt.directive=="%asm")
                    throw VmExecutionException("can't execute assembly code")
            }
            is VarDecl -> {
                // should have been defined already when the program started
            }
            is FunctionCallStatement -> {
                val target = stmt.target.targetStatement(program.namespace)
                when(target) {
                    is Subroutine -> {
                        val args = evaluate(stmt.arglist)
                        if(target.isAsmSubroutine) {
                            performSyscall(target, args)
                        } else {
                            val results = executeSubroutine(target, args)
                            // TODO process result values
                        }
                    }
                    is BuiltinFunctionStatementPlaceholder -> {
                        val args = evaluate(stmt.arglist)
                        functions.performBuiltinFunction(target.name, args)
                    }
                    else -> {
                        TODO("CALL $target")
                    }
                }
            }
            is BuiltinFunctionStatementPlaceholder -> {
                TODO("builtinfun $stmt")
            }
            is Return -> throw LoopControlReturn(stmt.values.map { evaluate(it, evalCtx) })
            is Continue -> throw LoopControlContinue()
            is Break -> throw LoopControlBreak()
            is Assignment -> {
                if(stmt.aug_op!=null)
                    throw VmExecutionException("augmented assignment should have been converted into regular one $stmt")
                val target = stmt.singleTarget
                if(target!=null) {
                    val value = evaluate(stmt.value, evalCtx)
                    when {
                        target.identifier!=null -> {
                            val decl = stmt.definingScope().lookup(target.identifier.nameInSource, stmt) as? VarDecl
                                    ?: throw VmExecutionException("can't find assignment target ${target.identifier}")
                            if(decl.type==VarDeclType.MEMORY) {
                                val address = runtimeVariables.getMemoryAddress(decl.definingScope(), decl.name)
                                when(decl.datatype) {
                                    DataType.UBYTE -> mem.setUByte(address, value.byteval!!)
                                    DataType.BYTE -> mem.setSByte(address, value.byteval!!)
                                    DataType.UWORD -> mem.setUWord(address, value.wordval!!)
                                    DataType.WORD -> mem.setSWord(address, value.wordval!!)
                                    DataType.FLOAT -> mem.setFloat(address, value.floatval!!)
                                    DataType.STR -> mem.setString(address, value.str!!)
                                    DataType.STR_S -> mem.setScreencodeString(address, value.str!!)
                                    else -> TODO("set memvar $decl")
                                }
                            } else
                                runtimeVariables.set(decl.definingScope(), decl.name, value)
                        }
                        target.memoryAddress!=null -> {
                            TODO("assign memory $stmt")
                        }
                        target.arrayindexed!=null -> {
                            val array = evaluate(target.arrayindexed.identifier, evalCtx)
                            val index = evaluate(target.arrayindexed.arrayspec.index, evalCtx)
                            when(array.type) {
                                DataType.ARRAY_UB -> {
                                    if(value.type!=DataType.UBYTE)
                                        throw VmExecutionException("new value is of different datatype ${value.type} for $array")
                                }
                                DataType.ARRAY_B -> {
                                    if(value.type!=DataType.BYTE)
                                        throw VmExecutionException("new value is of different datatype ${value.type} for $array")
                                }
                                DataType.ARRAY_UW -> {
                                    if(value.type!=DataType.UWORD)
                                        throw VmExecutionException("new value is of different datatype ${value.type} for $array")
                                }
                                DataType.ARRAY_W -> {
                                    if(value.type!=DataType.WORD)
                                        throw VmExecutionException("new value is of different datatype ${value.type} for $array")
                                }
                                DataType.ARRAY_F -> {
                                    if(value.type!=DataType.FLOAT)
                                        throw VmExecutionException("new value is of different datatype ${value.type} for $array")
                                }
                                DataType.STR, DataType.STR_S -> {
                                    if(value.type !in ByteDatatypes)
                                        throw VmExecutionException("new value is of different datatype ${value.type} for $array")
                                }
                                else -> throw VmExecutionException("strange array type ${array.type}")
                            }
                            if(array.type in ArrayDatatypes)
                                array.array!![index.integerValue()] = value.numericValue()
                            else if(array.type in StringDatatypes) {
                                val indexInt = index.integerValue()
                                val newchr = Petscii.decodePetscii(listOf(value.numericValue().toShort()), true)
                                val newstr = array.str!!.replaceRange(indexInt, indexInt+1, newchr)
                                val ident = stmt.definingScope().lookup(target.arrayindexed.identifier.nameInSource, stmt) as? VarDecl
                                        ?: throw VmExecutionException("can't find assignment target ${target.identifier}")
                                val identScope = ident.definingScope()
                                program.heap.update(array.heapId!!, newstr)
                                runtimeVariables.set(identScope, ident.name, RuntimeValue(array.type, str=newstr, heapId=array.heapId))
                            }
                        }
                        target.register!=null -> {
                            runtimeVariables.set(program.namespace, target.register.name, value)
                        }
                        else -> TODO("assign $target")
                    }
                }
                else TODO("assign multitarget $stmt")
            }
            is PostIncrDecr -> {
                when {
                    stmt.target.identifier!=null -> {
                        val ident = stmt.definingScope().lookup(stmt.target.identifier!!.nameInSource, stmt) as VarDecl
                        val identScope = ident.definingScope()
                        var value = runtimeVariables.get(identScope, ident.name)
                        value = when {
                            stmt.operator=="++" -> value.add(RuntimeValue(value.type, 1))
                            stmt.operator=="--" -> value.sub(RuntimeValue(value.type, 1))
                            else -> throw VmExecutionException("strange postincdec operator $stmt")
                        }
                        runtimeVariables.set(identScope, ident.name, value)
                    }
                    stmt.target.memoryAddress!=null -> {
                        TODO("postincrdecr memory $stmt")
                    }
                    stmt.target.arrayindexed!=null -> {
                        TODO("postincrdecr array $stmt")
                    }
                }
            }
            is Jump -> {
                TODO("jump $stmt")
            }
            is InlineAssembly -> {
                if(sub is Subroutine) {
                    when(sub.scopedname) {
                        "c64flt.print_f" -> {
                            val arg = runtimeVariables.get(sub, sub.parameters.single().name)
                            performSyscall(sub, listOf(arg))
                        }
                        else -> TODO("simulate asm subroutine ${sub.scopedname}")
                    }
                    throw LoopControlReturn(emptyList())
                }
                throw VmExecutionException("can't execute inline assembly in $sub")
            }
            is AnonymousScope -> executeAnonymousScope(stmt)
            is IfStatement -> {
                val condition = evaluate(stmt.condition, evalCtx)
                if(condition.asBoolean)
                    executeAnonymousScope(stmt.truepart)
                else
                    executeAnonymousScope(stmt.elsepart)
            }
            is BranchStatement -> {
                TODO("branch $stmt")
            }
            is ForLoop -> {
                val iterable = evaluate(stmt.iterable, evalCtx)
                if (iterable.type !in IterableDatatypes && iterable !is RuntimeValueRange)
                    throw VmExecutionException("can only iterate over an iterable value:  $stmt")
                val loopvarDt: DataType
                val loopvar: IdentifierReference
                if(stmt.loopRegister!=null) {
                    loopvarDt = DataType.UBYTE
                    loopvar = IdentifierReference(listOf(stmt.loopRegister.name), stmt.position)
                }
                else {
                    loopvarDt = stmt.loopVar!!.resultingDatatype(program)!!
                    loopvar = stmt.loopVar
                }
                val iterator = iterable.iterator()
                for(loopvalue in iterator) {
                    try {
                        oneForCycle(stmt, loopvarDt, loopvalue, loopvar)
                    } catch (b: LoopControlBreak) {
                        break
                    } catch (c: LoopControlContinue) {
                        continue
                    }
                }
            }
            is WhileLoop -> {
                var condition = evaluate(stmt.condition, evalCtx)
                while (condition.asBoolean) {
                    try {
                        executeAnonymousScope(stmt.body)
                        condition = evaluate(stmt.condition, evalCtx)
                    } catch(b: LoopControlBreak) {
                        break
                    } catch(c: LoopControlContinue){
                        continue
                    }
                }
            }
            is RepeatLoop -> {
                do {
                    val condition = evaluate(stmt.untilCondition, evalCtx)
                    try {
                        executeAnonymousScope(stmt.body)
                    } catch(b: LoopControlBreak) {
                        break
                    } catch(c: LoopControlContinue){
                        continue
                    }
                } while(!condition.asBoolean)
            }
            else -> {
                TODO("implement $stmt")
            }
        }
    }

    private fun oneForCycle(stmt: ForLoop, loopvarDt: DataType, loopValue: Number, loopVar: IdentifierReference) {
        val value: LiteralValue =
                when (loopvarDt) {
                    DataType.UBYTE -> LiteralValue(DataType.UBYTE, loopValue.toShort(), position = stmt.position)
                    DataType.BYTE -> LiteralValue(DataType.BYTE, loopValue.toShort(), position = stmt.position)
                    DataType.UWORD -> LiteralValue(DataType.UWORD, wordvalue = (loopValue as Int), position = stmt.position)
                    DataType.WORD -> LiteralValue(DataType.WORD, wordvalue = (loopValue as Int), position = stmt.position)
                    DataType.FLOAT -> LiteralValue(DataType.FLOAT, floatvalue = (loopValue as Double), position = stmt.position)
                    else -> TODO("weird loopvar type $loopvarDt")
                }
        val assignment = Assignment(listOf(AssignTarget(null, loopVar, null, null,
                position = loopVar.position)), null, value, stmt.iterable.position)
        assignment.linkParents(stmt.body)
        executeStatement(stmt.body, assignment)   // assign the new loop value to the loopvar
        executeAnonymousScope(stmt.body)   // and run the code
    }

    private fun evaluate(args: List<IExpression>): List<RuntimeValue>  = args.map {
        evaluate(it, EvalContext(program, mem, runtimeVariables, functions, ::executeSubroutine))
    }

    private fun performSyscall(sub: Subroutine, args: List<RuntimeValue>) {
        assert(sub.isAsmSubroutine)
        when(sub.scopedname) {
            "c64scr.print" -> {
                // if the argument is an UWORD, consider it to be the "address" of the string (=heapId)
                if(args[0].wordval!=null) {
                    val str = program.heap.get(args[0].wordval!!).str!!
                    dialog.canvas.printText(str, 1, true)
                }
                else
                    dialog.canvas.printText(args[0].str!!, 1, true)
            }
            "c64scr.print_ub" -> {
                dialog.canvas.printText(args[0].byteval!!.toString(), 1, true)
            }
            "c64scr.print_b" -> {
                dialog.canvas.printText(args[0].byteval!!.toString(), 1, true)
            }
            "c64scr.print_ubhex" -> {
                val prefix = if(args[0].asBoolean) "$" else ""
                val number = args[1].byteval!!
                dialog.canvas.printText("$prefix${number.toString(16).padStart(2, '0')}", 1, true)
            }
            "c64scr.print_uw" -> {
                dialog.canvas.printText(args[0].wordval!!.toString(), 1, true)
            }
            "c64scr.print_w" -> {
                dialog.canvas.printText(args[0].wordval!!.toString(), 1, true)
            }
            "c64scr.print_uwhex" -> {
                val prefix = if(args[0].asBoolean) "$" else ""
                val number = args[1].wordval!!
                dialog.canvas.printText("$prefix${number.toString(16).padStart(4, '0')}", 1, true)
            }
            "c64.CHROUT" -> {
                dialog.canvas.printChar(args[0].byteval!!)
            }
            "c64flt.print_f" -> {
                dialog.canvas.printText(args[0].floatval.toString(), 1, true)
            }
            else -> TODO("syscall  ${sub.scopedname} $sub")
        }
    }


    private fun setFlags(value: LiteralValue?) {
        if(value!=null) {
            when(value.type) {
                DataType.UBYTE -> {
                    val v = value.bytevalue!!.toInt()
                    P_negative = v>127
                    P_zero = v==0
                }
                DataType.BYTE -> {
                    val v = value.bytevalue!!.toInt()
                    P_negative = v<0
                    P_zero = v==0
                }
                DataType.UWORD -> {
                    val v = value.wordvalue!!
                    P_negative = v>32767
                    P_zero = v==0
                }
                DataType.WORD -> {
                    val v = value.wordvalue!!
                    P_negative = v<0
                    P_zero = v==0
                }
                DataType.FLOAT -> {
                    val flt = value.floatvalue!!
                    P_negative = flt < 0.0
                    P_zero = flt==0.0
                }
                else -> {
                    // no flags for non-numeric type
                }
            }
        }
    }
}