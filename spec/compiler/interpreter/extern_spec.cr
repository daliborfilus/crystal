{% skip_file if flag?(:without_interpreter) %}
require "./spec_helper"

describe Crystal::Repl::Interpreter do
  context "extern" do
    it "interprets primitive struct_or_union_set and get (struct)" do
      interpret(<<-CODE).should eq(30)
          lib LibFoo
            struct Foo
              x : Int32
              y : Int32
            end
          end

          foo = LibFoo::Foo.new
          foo.x = 10
          foo.y = 20
          foo.x + foo.y
        CODE
    end

    it "discards primitive struct_or_union_set and get (struct)" do
      interpret(<<-CODE).should eq(10)
          lib LibFoo
            struct Foo
              x : Int32
              y : Int32
            end
          end

          foo = LibFoo::Foo.new
          foo.y = 10
        CODE
    end

    it "discards primitive struct_or_union_set because it's a copy" do
      interpret(<<-CODE).should eq(10)
          lib LibFoo
            struct Foo
              x : Int32
              y : Int32
            end
          end

          def copy
            LibFoo::Foo.new
          end

          copy.y = 10
        CODE
    end

    it "interprets primitive struct_or_union_set and get (union)" do
      interpret(<<-CODE).should eq(-2045911175)
          lib LibFoo
            union Foo
              a : Bool
              x : Int64
              y : Int32
            end
          end

          foo = LibFoo::Foo.new
          foo.x = 123456789012345
          foo.y
        CODE
    end

    it "sets extern struct proc field" do
      interpret(<<-CODE).should eq(13)
          lib LibFoo
            struct Foo
              proc : Int32 -> Int32
              field : Int32
            end
          end

          foo = LibFoo::Foo.new
          foo.field = 10
          foo.proc = ->(x : Int32) { x + 1 }
          foo.proc.call(2) + foo.field
        CODE
    end

    it "sets struct field through pointer" do
      interpret(<<-CODE).should eq(20)
          lib LibFoo
            struct Foo
              x : Int32
            end
          end

          foo = LibFoo::Foo.new
          ptr = pointerof(foo)
          ptr.value.x = 20
          foo.x
        CODE
    end

    it "does automatic C cast" do
      interpret(<<-CODE).should eq(1)
          lib LibFoo
            struct Foo
              x : UInt8
            end
          end

          foo = LibFoo::Foo.new
          foo.x = 257
          foo.x
        CODE
    end
  end
end
