module PubkeyAudit
  class User
    module CSVConverters
      BLANK_TO_NIL = -> (f) { f.empty? ? nil : f }
      TRIM_WHITESPACE = -> (f) { f.respond_to?(:gsub) ? f.gsub(/\s+$/, '') : f }

      CSV_SETTINGS = {
        :headers => true,
        :header_converters => :symbol,
        :converters => [BLANK_TO_NIL, TRIM_WHITESPACE],
      }
    end
  end
end