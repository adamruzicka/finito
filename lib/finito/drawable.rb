gem 'sourcify'

module Finito
  # Modle marking the object it is included into as drawable.
  # It requires {#draw} method to be implemented which returns
  # the object's representation in graphviz language.
  module Drawable

    # Renders the object in graphviz language
    #
    # @abstract Implement in the class the module is included in to make
    #   it drawable
    # @return [String] representation of the object in graphviz language
    def draw
      raise NotImplementedError
    end

    # Helper to output colored text
    #
    # @param text [String] the text to be colorised
    # @param color [String] the color
    # @return [String] graphviz HTML-like tag coloring the text
    def font_color(text, color)
      %(<FONT COLOR="#{color}">#{text}</FONT>)
    end

    # Helper to format source of a proc
    #
    # @param block [Proc,Symbol] the callable to get its source code
    # @return [String] textual representation of the block
    def proc_to_text(block)
      case block
      when Symbol
        block
      when Proc
        block.to_source.tr('"', "'")
      end
    end
  end
end
