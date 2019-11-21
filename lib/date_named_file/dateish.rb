# frozen_string_literal: true

require 'date'
module DateNamedFile

  class InvalidDateFormat < StandardError
  end

  class NonDigitsInDelimitedDate < InvalidDateFormat
  end

  class NonTwoDigitDateParts < InvalidDateFormat
  end

  # Provide some simple and very naïve methods to turn something that might be a date
  # into a date.
  module DateishHelpers

    ALL_DIGITS       = /\A\d+\Z/
    VALID_DELIMITERS = /[-_ :]/

    # Attempt to turn big integer (turned into a string of digits),
    # an actual string of digits, or a delimited
    # string of digits (delimited by chars in VALID_DELIMITERS) into
    # a DateTime.
    #
    # Should handle:
    #  * Something that's already a Date or Datetime, which just returns
    #    itself as a DateTime.
    #  * unix timestamp (see #extract_unix_timestamp)
    #  * string of digits (see #extract_undelimited_datetime)
    #  * delimited string of digits (see #extract_delimited_datetime)
    # @param [#to_datetime, Integer, String] date_ish The thing to try to convert
    # @return [DateTime] Our best shot at a datetime
    # @raise [InvalidDateFormat] if we can't pull a datetime out of it
    def forgiving_dateify(date_ish)
      if date_ish.respond_to? :to_datetime
        date_ish.to_datetime
      else
        str = date_ish.to_s
        if digit_string?(str)
          extract_from_digitstring(str) or
            raise InvalidDateFormat.new("All-digit string '#{str}' doesn't parse as date string or unix timestamp")
        else
          extract_delimited_datetime(str)
        end
      end
    rescue InvalidDateFormat => e
      raise InvalidDateFormat.new("Can't turn '#{date_ish}' into a date-time: #{e.message}")
    end


    def extract_from_digitstring(str)
      extract_unix_timestamp(str) or
        extract_undelimited_datetime(str)
    end

    # An undelimited datetime is a string of digits at least
    # eight digits long (to get YYYYMMDD). Anything after that
    # is pulled out into two-digit chunks and sent along to
    # DateTime.new as integers. This means:
    # * YYYYMMDD is always necessary; everything after that is optional
    # * The rest must be in order: Hour, Minute, Second
    # * Everything is assumed to be two digits and zero-padded
    #
    # Limitations:
    # * No support for milliseconds with normal dates. Milliseconds are
    # parsed but silently thrown out. Because c'mon, really?
    # @param [String<0-9>] digit_string A string of digits
    # @return [DateTime, FalseClass] The valid DateTime, or false (for chaining)
    def extract_undelimited_datetime(digit_string)
      return false unless digit_string?(digit_string)
      m = /\A(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?\d*\Z/.match(digit_string)
      if m
        datetime_from_parts(m[1..-1].compact)
      else
        false
      end
    end

    # Any string that is (a) exactly 10 digits, and (b) starts with '1'
    # will be considered a unix timestamp and treated as such
    # LIMITATION: Only good back to Sept 2001
    # @param [String<0-9>] digit_string A string of digits, should be a unix timestamp
    # @return [DateTime, FalseClass] The valid DateTime, or false (for chaining)
    def extract_unix_timestamp(digit_string)
      if looks_like_unix_timestamp?(digit_string)
        DateTime.strptime(digit_string, '%s')
      else
        false
      end
    end

    # Is this plausible a modern unix timestamp? Valid back to 2001
    # @param [String] digit_string
    # @return [Boolean]
    def looks_like_unix_timestamp?(digit_string)
      digit_string?(digit_string) and
        digit_string.size == 10 and
        /\A1[0-9]/.match(digit_string[0..1])
    end


    def extract_delimited_datetime(str)
      validate_delimited_datetime!(str)
      year           = extract_year(str)
      non_year_parts = extract_non_year_parts(str)
      all_parts      = non_year_parts.unshift(year)
      datetime_from_parts(all_parts)
    rescue ArgumentError => e
      # presumably a DateTime parse error
      false
    rescue NonTwoDigitDateParts
      raise InvalidDateFormat.new("Trying to parse as delimited date. '#{str}' looks to have non-two-digit parts (no zero padding?).")
    rescue NonDigitsInDelimitedDate
      raise InvalidDateFormat.new("Trying to parse as delimited date. '#{str}' looks to have non-digits between delimiters.")
    end

    def datetime_from_parts(parts)
      year           = parts[0]
      non_year_parts = parts[1..-1].map { |dstring| dstring.scan(/\d\d/) }.flatten
      all_parts      = non_year_parts.unshift(year).map(&:to_i)
      DateTime.new(*all_parts)
    rescue ArgumentError
      raise InvalidDateFormat.new("DateTime.new rejected extracted parts ([#{parts.join(',')}]).")
    end

    def extract_non_year_parts(str)
      parts = extract_rest(str).split(VALID_DELIMITERS)
      validate_parts!(parts)
      parts
    end

    def validate_parts!(parts)
      unless parts.all? { |p| digit_string?(p) }
        raise NonDigitsInDelimitedDate.new
      end

      unless parts.all? { |p| p.size == 2 }
        raise NonTwoDigitDateParts.new
      end
    end



    def digit_string?(str)
      ALL_DIGITS.match(str)
    end

    def validate_delimited_datetime!(str)
      /\A\d{4}/.match(str) or raise InvalidDateFormat.new("'#{str}' doesn't obviously start with a year")
    end

    def extract_year(str)
      str[0..3]
    end

    def extract_rest(str)
      everything_after_the_year = str[4..-1]
      ditch_leading_delimiters(everything_after_the_year)
    end

    def ditch_leading_delimiters(str)
      str.sub(/\A#{VALID_DELIMITERS}/, '')
    end


  end

  module Dateish
    extend DateNamedFile::DateishHelpers
  end
end
