# frozen_string_literal: true

module Postsvg
  # LIFO stack of immutable GraphicsContext snapshots. +gsave+ pushes
  # a duplicate of the current top; +grestore+ pops. Popping an empty
  # stack is a no-op (mirrors PLRM §7.2.2).
  class GraphicsStack
    def initialize(initial: GraphicsContext.new)
      @stack = [initial]
    end

    def current
      @stack.last
    end

    def push
      @stack.push(current)
      self
    end
    alias gsave push

    def pop
      return current if @stack.size == 1

      @stack.pop
      current
    end
    alias grestore pop

    def depth
      @stack.size
    end

    def replace(new_state)
      @stack[-1] = new_state
      new_state
    end

    def update(**overrides)
      replace(current.with(**overrides))
    end
  end
end
