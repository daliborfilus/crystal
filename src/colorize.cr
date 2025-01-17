# With `Colorize` you can change the fore- and background colors and text decorations when rendering text
# on terminals supporting ANSI escape codes. It adds the `colorize` method to `Object` and thus all classes
# as its main interface, which calls `to_s` and surrounds it with the necessary escape codes
# when it comes to obtaining a string representation of the object.
#
# Its first argument changes the foreground color:
#
# ```
# require "colorize"
#
# "foo".colorize(:green)
# 100.colorize(:red)
# [1, 2, 3].colorize(:blue)
# ```
#
# There are alternative ways to change the foreground color:
#
# ```
# require "colorize"
#
# "foo".colorize.fore(:green)
# "foo".colorize.green
# ```
#
# To change the background color, the following methods are available:
#
# ```
# require "colorize"
#
# "foo".colorize.back(:green)
# "foo".colorize.on(:green)
# "foo".colorize.on_green
# ```
#
# You can also pass an RGB color to `colorize`:
#
# ```
# require "colorize"
#
# "foo".colorize(0, 255, 255) # => "foo" in aqua
#
# # This is the same as:
#
# "foo".colorize(Colorize::ColorRGB.new(0, 255, 255)) # => "foo" in aqua
# ```
#
# Or an 8-bit color:
#
# ```
# require "colorize"
#
# "foo".colorize(Colorize::Color256.new(208)) # => "foo" in orange
# ```
#
# It's also possible to change the text decoration:
#
# ```
# require "colorize"
#
# "foo".colorize.mode(:underline)
# "foo".colorize.underline
# ```
#
# The `colorize` method returns a `Colorize::Object` instance,
# which allows chaining methods together:
#
# ```
# require "colorize"
#
# "foo".colorize.fore(:yellow).back(:blue).mode(:underline)
# ```
#
# With the `toggle` method you can temporarily disable adding the escape codes.
# Settings of the instance are preserved however and can be turned back on later:
#
# ```
# require "colorize"
#
# "foo".colorize(:red).toggle(false)              # => "foo" without color
# "foo".colorize(:red).toggle(false).toggle(true) # => "foo" in red
# ```
#
# The color `:default` leaves the object's representation as it is but the object is a `Colorize::Object` then
# which is handy in conditions such as:
#
# ```
# require "colorize"
#
# "foo".colorize(Random::DEFAULT.next_bool ? :green : :default)
# ```
#
# Available colors are:
# ```
# :default
# :black
# :red
# :green
# :yellow
# :blue
# :magenta
# :cyan
# :light_gray
# :dark_gray
# :light_red
# :light_green
# :light_yellow
# :light_blue
# :light_magenta
# :light_cyan
# :white
# ```
#
# Available text decorations are:
# ```
# :bold
# :bright
# :dim
# :underline
# :blink
# :reverse
# :hidden
# ```
module Colorize
  # Objects will only be colored if this is `true`.
  #
  # ```
  # require "colorize"
  #
  # Colorize.enabled = true
  # "hello".colorize.red.to_s # => "\e[31mhello\e[0m"
  #
  # Colorize.enabled = false
  # "hello".colorize.red.to_s # => "hello"
  # ```
  #
  # NOTE: This is by default disabled on non-TTY devices because they likely don't support ANSI escape codes.
  # This will also be disabled if the environment variable `TERM` is "dumb".
  class_property? enabled : Bool = true

  # Makes `Colorize.enabled` `true` if and only if both of `STDOUT.tty?`
  # and `STDERR.tty?` are `true` and the tty is not considered a dumb terminal.
  # This is determined by the environment variable called `TERM`.
  # If `TERM=dumb`, color won't be enabled.
  def self.on_tty_only!
    self.enabled = STDOUT.tty? && STDERR.tty? && ENV["TERM"]? != "dumb"
  end

  # Resets the color and text decoration of the *io*.
  #
  # ```
  # with_color.green.surround(io) do
  #   io << "green"
  #   Colorize.reset
  #   io << " default"
  # end
  # ```
  def self.reset(io = STDOUT)
    io << "\e[0m" if enabled?
  end

  # Helper method to use colorize with `IO`.
  #
  # ```
  # io = IO::Memory.new
  # io << "not-green"
  # Colorize.with.green.bold.surround(io) do
  #   io << "green and bold if Colorize.enabled"
  # end
  # ```
  def self.with : Colorize::Object(String)
    "".colorize
  end
end

module Colorize::ObjectExtensions
  # Turns `self` into a `Colorize::Object`.
  def colorize : Colorize::Object
    Colorize::Object.new(self)
  end

  # Turns `self` into a `Colorize::Object` and colors it with a color.
  def colorize(fore)
    Colorize::Object.new(self).fore(fore)
  end
end

class Object
  include Colorize::ObjectExtensions
end

module Colorize
  alias Color = ColorANSI | Color256 | ColorRGB

  # One color of a fixed set of colors.
  enum ColorANSI
    Default      = 39
    Black        = 30
    Red          = 31
    Green        = 32
    Yellow       = 33
    Blue         = 34
    Magenta      = 35
    Cyan         = 36
    LightGray    = 37
    DarkGray     = 90
    LightRed     = 91
    LightGreen   = 92
    LightYellow  = 93
    LightBlue    = 94
    LightMagenta = 95
    LightCyan    = 96
    White        = 97

    def fore(io : IO) : Nil
      to_i.to_s io
    end

    def back(io : IO) : Nil
      (to_i + 10).to_s io
    end
  end

  # An 8-bit color.
  record Color256,
    value : UInt8 do
    def fore(io : IO) : Nil
      io << "38;5;"
      value.to_s io
    end

    def back(io : IO) : Nil
      io << "48;5;"
      value.to_s io
    end
  end

  # An RGB color.
  record ColorRGB,
    red : UInt8,
    green : UInt8,
    blue : UInt8 do
    def fore(io : IO) : Nil
      io << "38;2;"
      io << red << ";"
      io << green << ";"
      io << blue
    end

    def back(io : IO) : Nil
      io << "48;2;"
      io << red << ";"
      io << green << ";"
      io << blue
    end
  end
end

# A colorized object. Colors and text decorations can be modified.
struct Colorize::Object(T)
  private MODE_DEFAULT   = '0'
  private MODE_BOLD      = '1'
  private MODE_BRIGHT    = '1'
  private MODE_DIM       = '2'
  private MODE_UNDERLINE = '4'
  private MODE_BLINK     = '5'
  private MODE_REVERSE   = '7'
  private MODE_HIDDEN    = '8'

  private MODE_BOLD_FLAG      =  1
  private MODE_BRIGHT_FLAG    =  1
  private MODE_DIM_FLAG       =  2
  private MODE_UNDERLINE_FLAG =  4
  private MODE_BLINK_FLAG     =  8
  private MODE_REVERSE_FLAG   = 16
  private MODE_HIDDEN_FLAG    = 32

  private COLORS = %w(default black red green yellow blue magenta cyan light_gray dark_gray light_red light_green light_yellow light_blue light_magenta light_cyan white)
  private MODES  = %w(bold bright dim underline blink reverse hidden)

  @fore : Color
  @back : Color

  def initialize(@object : T)
    @fore = ColorANSI::Default
    @back = ColorANSI::Default
    @mode = 0
    @enabled = Colorize.enabled?
  end

  {% for name in COLORS %}
    def {{name.id}}
      @fore = ColorANSI::{{name.camelcase.id}}
      self
    end

    def on_{{name.id}}
      @back = ColorANSI::{{name.camelcase.id}}
      self
    end
  {% end %}

  {% for name in MODES %}
    def {{name.id}}
      @mode |= MODE_{{name.upcase.id}}_FLAG
      self
    end
  {% end %}

  def fore(color : Symbol) : self
    {% for name in COLORS %}
      if color == :{{name.id}}
        @fore = ColorANSI::{{name.camelcase.id}}
        return self
      end
    {% end %}

    raise ArgumentError.new "Unknown color: #{color}"
  end

  def fore(@fore : Color) : self
    self
  end

  def back(color : Symbol) : self
    {% for name in COLORS %}
      if color == :{{name.id}}
        @back = ColorANSI::{{name.camelcase.id}}
        return self
      end
    {% end %}

    raise ArgumentError.new "Unknown color: #{color}"
  end

  def back(@back : Color) : self
    self
  end

  def mode(mode : Symbol) : self
    {% for name in MODES %}
      if mode == :{{name.id}}
        @mode |= MODE_{{name.upcase.id}}_FLAG
        return self
      end
    {% end %}

    raise ArgumentError.new "Unknown mode: #{mode}"
  end

  def on(color : Symbol)
    back color
  end

  # Enables or disables colors and text decoration on this object.
  def toggle(flag)
    @enabled = !!flag
    self
  end

  # Appends this object colored and with text decoration to *io*.
  def to_s(io : IO) : Nil
    surround(io) do
      io << @object
    end
  end

  # Inspects this object and makes the ANSI escape codes visible.
  def inspect(io : IO) : Nil
    surround(io) do
      @object.inspect(io)
    end
  end

  # Surrounds *io* by the ANSI escape codes and lets you build colored strings:
  #
  # ```
  # require "colorize"
  #
  # io = IO::Memory.new
  #
  # with_color.red.surround(io) do
  #   io << "colorful"
  #   with_color.green.bold.surround(io) do
  #     io << " hello "
  #   end
  #   with_color.blue.surround(io) do
  #     io << "world"
  #   end
  #   io << " string"
  # end
  #
  # io.to_s # returns a colorful string where "colorful" is red, "hello" green, "world" blue and " string" red again
  # ```
  def surround(io = STDOUT)
    return yield io unless @enabled

    Object.surround(io, to_named_tuple) do |io|
      yield io
    end
  end

  private def to_named_tuple
    {
      fore: @fore,
      back: @back,
      mode: @mode,
    }
  end

  @@last_color = {
    fore: ColorANSI::Default.as(Color),
    back: ColorANSI::Default.as(Color),
    mode: 0,
  }

  protected def self.surround(io, color)
    last_color = @@last_color
    must_append_end = append_start(io, color)
    @@last_color = color

    begin
      yield io
    ensure
      append_start(io, last_color) if must_append_end
      @@last_color = last_color
    end
  end

  private def self.append_start(io, color)
    last_color_is_default =
      @@last_color[:fore] == ColorANSI::Default &&
        @@last_color[:back] == ColorANSI::Default &&
        @@last_color[:mode] == 0

    fore = color[:fore]
    back = color[:back]
    mode = color[:mode]

    fore_is_default = fore == ColorANSI::Default
    back_is_default = back == ColorANSI::Default
    mode_is_default = mode == 0

    if fore_is_default && back_is_default && mode_is_default && last_color_is_default || @@last_color == color
      false
    else
      io << "\e["

      printed = false

      unless last_color_is_default
        io << MODE_DEFAULT
        printed = true
      end

      unless fore_is_default
        io << ';' if printed
        fore.fore io
        printed = true
      end

      unless back_is_default
        io << ';' if printed
        back.back io
        printed = true
      end

      unless mode_is_default
        # Can't reuse MODES constant because it has bold/bright duplicated
        {% for name in %w(bold dim underline blink reverse hidden) %}
          if mode.bits_set? MODE_{{name.upcase.id}}_FLAG
            io << ';' if printed
            io << MODE_{{name.upcase.id}}
            printed = true
          end
        {% end %}
      end

      io << 'm'

      true
    end
  end
end
