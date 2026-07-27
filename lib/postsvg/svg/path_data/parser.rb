# frozen_string_literal: true

module Postsvg
  module Svg
    module PathData
      # Tokenizer + parser for SVG path data. Handles the standard
      # grammar from SVG 1.1 §8.3. Output is a list of Command value
      # objects with normalized argument counts.
      module Parser
        module_function

        COMMAND_RE = /([MmLlHhVvCcSsQqTtAaZz])/
        ARG_RE = /(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)/

        def parse(text)
          return [] if text.nil? || text.empty?

          commands = []
          tokens = tokenize(text)
          i = 0
          while i < tokens.length
            opcode = tokens[i]
            i += 1
            arity = arity_for(opcode)
            if arity.zero?
              commands << Command.new(opcode: opcode, args: [])
              next
            end

            # Repeat: M / L / C etc. can have multiple coordinate
            # tuples after a single opcode. Consume in groups of arity.
            loop do
              args, consumed = take_args(tokens, i, arity)
              break unless consumed == arity

              commands << Command.new(opcode: opcode, args: args)
              i += consumed
              # After moveto, implicit lineto for subsequent tuples.
              opcode = if opcode == "M"
                         "L"
                       else
                         (opcode == "m" ? "l" : opcode)
                       end
              # For H/V/Z, no implicit repetition.
              break if %w[H V Z h v z].include?(opcode)
            end
          end
          commands
        end

        def arity_for(opcode)
          case opcode.upcase
          when "M", "L", "T" then 2
          when "H", "V" then 1
          when "C" then 6
          when "S", "Q" then 4
          when "A" then 7
          when "Z" then 0
          else 0
          end
        end

        def tokenize(text)
          text.to_s.gsub("-", " -")
            .scan(/([MmLlHhVvCcSsQqTtAaZz])|(-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)/)
            .flatten.compact
        end

        NUMBER_ONLY_RE = /\A-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/

        def take_args(tokens, start, count)
          args = []
          consumed = 0
          while consumed < count && start + consumed < tokens.length
            tok = tokens[start + consumed]
            break unless NUMBER_ONLY_RE.match?(tok.to_s)

            args << tok.to_f
            consumed += 1
          end
          [args, consumed]
        end
      end
    end
  end
end
