require "./repl"

class Crystal::Repl::Constants
  def initialize(@context : Context)
    @types = {} of Const => Type
    @const_to_index = {} of Const => Int32
    @index_to_compiled_def = {} of Int32 => CompiledDef
    @bytesize = 0
  end

  def bytesize
    @bytesize
  end

  def declare(const : Const, compiled_def : CompiledDef) : Int32
    type = const.value.type

    index = @bytesize
    @const_to_index[const] = index
    @index_to_compiled_def[index] = compiled_def

    @types[const] = type
    @bytesize += 1 # We need a bit to know if the constant was already initialized
    @bytesize += @context.sizeof_type(type)

    index
  end

  def const_to_index?(const : Const) : Int32?
    @const_to_index[const]?
  end

  def index_to_compiled_def(index : Int32) : CompiledDef
    @index_to_compiled_def[index]
  end
end