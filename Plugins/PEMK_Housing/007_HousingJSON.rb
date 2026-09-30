#===============================================================================
# PEMK_Housing :: 007 JSON
#-------------------------------------------------------------------------------
# Pure-Ruby JSON parser for mkxp-z / RGSS (where stdlib json is absent).
# Supports objects, arrays, strings (with escapes), numbers, booleans, null.
#===============================================================================
module PEMK
  module HousingJSON
    module_function

    def parse(str, symbolize_names: false)
      return nil if str.nil? || str.to_s.strip.empty?
      if defined?(::JSON)
        begin
          return ::JSON.parse(str, symbolize_names: symbolize_names)
        rescue StandardError
        end
      end
      Parser.new(str, symbolize_names: symbolize_names).parse
    end

    def dump(obj)
      if defined?(::JSON)
        begin
          return ::JSON.dump(obj)
        rescue StandardError
        end
      end
      generate_simple(obj)
    end

    def generate(obj)
      dump(obj)
    end

    def generate_simple(obj)
      case obj
      when nil          then "null"
      when true         then "true"
      when false        then "false"
      when Numeric      then obj.to_s
      when String, Symbol then "\"#{obj.to_s.gsub('"', '\"')}\""
      when Array        then "[#{obj.map { |v| generate_simple(v) }.join(',')}]"
      when Hash         then "{#{obj.map { |k, v| "#{generate_simple(k.to_s)}:#{generate_simple(v)}" }.join(',')}}"
      else "\"#{obj.to_s}\""
      end
    end

    class Parser
      def initialize(str, symbolize_names: false)
        @str = str.to_s
        @pos = 0
        @len = @str.bytesize
        @symbolize = symbolize_names
      end

      def parse
        skip_whitespace
        val = parse_value
        skip_whitespace
        val
      end

      private

      def skip_whitespace
        while @pos < @len
          b = @str.getbyte(@pos)
          break unless b == 32 || b == 9 || b == 10 || b == 13 # space, tab, LF, CR
          @pos += 1
        end
      end

      def parse_value
        return nil if @pos >= @len
        b = @str.getbyte(@pos)
        case b
        when 123 # '{'
          parse_object
        when 91 # '['
          parse_array
        when 34 # '"'
          parse_string
        when 116 # 't'
          expect("true", true)
        when 102 # 'f'
          expect("false", false)
        when 110 # 'n'
          expect("null", nil)
        when 45, 48..57 # '-', '0'..'9'
          parse_number
        else
          raise "JSON parse error at char #{@pos}: unexpected byte #{b}"
        end
      end

      def parse_object
        @pos += 1
        skip_whitespace
        obj = {}
        return obj if @pos < @len && @str.getbyte(@pos) == 125 # '}'
        loop do
          skip_whitespace
          raise "Expected string key in object at #{@pos}" unless @str.getbyte(@pos) == 34
          key = parse_string
          key = key.to_sym if @symbolize
          skip_whitespace
          raise "Expected ':' after key at #{@pos}" unless @str.getbyte(@pos) == 58
          @pos += 1
          skip_whitespace
          val = parse_value
          obj[key] = val
          skip_whitespace
          b = @str.getbyte(@pos)
          if b == 44 # ','
            @pos += 1
          elsif b == 125 # '}'
            @pos += 1
            break
          else
            raise "Expected ',' or '}' in object at #{@pos}"
          end
        end
        obj
      end

      def parse_array
        @pos += 1
        skip_whitespace
        arr = []
        return arr if @pos < @len && @str.getbyte(@pos) == 93 # ']'
        loop do
          skip_whitespace
          arr << parse_value
          skip_whitespace
          b = @str.getbyte(@pos)
          if b == 44 # ','
            @pos += 1
          elsif b == 93 # ']'
            @pos += 1
            break
          else
            raise "Expected ',' or ']' in array at #{@pos}"
          end
        end
        arr
      end

      def parse_string
        @pos += 1
        out = String.new
        while @pos < @len
          b = @str.getbyte(@pos)
          if b == 34 # '"'
            @pos += 1
            return out.force_encoding("UTF-8")
          elsif b == 92 # '\'
            @pos += 1
            esc = @str.getbyte(@pos)
            @pos += 1
            case esc
            when 34 then out << '"'
            when 92 then out << '\\'
            when 47 then out << '/'
            when 98 then out << "\b"
            when 102 then out << "\f"
            when 110 then out << "\n"
            when 114 then out << "\r"
            when 116 then out << "\t"
            when 117 # 'u'
              hex = @str.byteslice(@pos, 4)
              @pos += 4
              out << [hex.hex].pack("U")
            else
              out << esc.chr
            end
          else
            out << b.chr
            @pos += 1
          end
        end
        out.force_encoding("UTF-8")
      end

      def parse_number
        start_pos = @pos
        @pos += 1 if @str.getbyte(@pos) == 45
        while @pos < @len
          b = @str.getbyte(@pos)
          break unless (48..57).cover?(b) || b == 46 || b == 69 || b == 101 || b == 43 || b == 45
          @pos += 1
        end
        num_str = @str.byteslice(start_pos, @pos - start_pos)
        num_str.include?(".") || num_str.include?("e") || num_str.include?("E") ? num_str.to_f : num_str.to_i
      end

      def expect(keyword, ret)
        len = keyword.bytesize
        if @str.byteslice(@pos, len) == keyword
          @pos += len
          ret
        else
          raise "Expected '#{keyword}' at #{@pos}"
        end
      end
    end
  end
end

