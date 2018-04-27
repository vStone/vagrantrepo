module Slop
  # Monkeypatch for help output
  class Option
    def to_s(offset: 0)
      to_s_multiline(true, offset).chomp
    end

    # Returns the help text for this option (flags and description).
    def to_s_multiline(printdefault = true, offset = 0)
      white_offset = format("\n%-#{offset + 6}<white>s", white: ' ')
      desc_str = desc
      unless desc.nil?
        desc_str = desc
        unless !printdefault || default_value.nil?
          default_str = "default: `#{default_value}`"
          spacing_str = desc_str.end_with?("\n") ? '' : ' '
          desc_str = "#{desc}#{spacing_str}[#{default_str}]"
        end
        desc_str.gsub!(/\n/, white_offset)
        desc_str
      end

      format("%-#{offset}<flag>s  %<desc>s", flag: flag, desc: desc_str)
    end
  end

  # Monkeypatch boolean help output
  class BoolOption
    def to_s(offset: 0)
      to_s_multiline(false, offset).chomp
    end
  end
end
