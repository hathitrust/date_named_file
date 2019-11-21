# frozen_string_literal: true

module DateNamedFile

  # A Template is a model of a filename with a (restricted but) valid
  # strftime formatting template embedded between angle brackets.
  #
  # Examples:
  # * daily_update_<%Y-%m-%d>.txt
  # * mydaemon_<%Y_%m_%d_%H%M>.log
  # * updates<%Y%m%d>_dev.ndj.gz
  #
  # In all cases:
  # * The year must be present and four digits
  # * Date/time parts must be in order (year, month, day, hour, minute, second)
  # * Everything that's not a year must be two digits, zero-padded if necessary
  class Template
    INNTER_STRFTIME_TEMPLATE_MATCHER = /<(.*?)>/


    # @return [Regexp] A regular expression that does its best to correctly match
    #   filenames that follow the template. Also used to try to extract the embedded
    #   date in a filename
    attr_reader :matcher

    # @private
    attr_accessor :strftime_template


    # @param [String] template Template string with embedded strftime format string in angle brackets
    # @example
    #   tmpl = DateNamedFile::Template.new("mystuff_daily<%Y%m%d>.tsv")
    def initialize(template)
      self.template_string = template
    end


    # @overload template_string
    #   @return [String] the template string, with embedded angle brackets and all
    # @overload template_string=(template)
    #   Set the template string and computes a new matcher (see #matcher)
    #   @param [String] template the new template string, with embedded angle brackets and all
    #   @return [self]
    attr_reader :template_string

    def template_string=(template)
      @template_string = template
      @matcher = template_matcher(template)
      strftime_template = @template.gsub(/[<>]/, '')
      self
    end

    # Compute the filename from plugging the given date_ish string/integer
    # into the template
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    # @return [String] the expanded filename
    def filename_for(date_ish)
      forgiving_dateify(date_ish).strftime(@strftime_template)
    end

    # Get a DateNamedFile::File for the given date/datetime
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    # @return [DateNamedFile::File] DateNamedFile::File for the given date in this template
    def at(date_ish)
      DatedFile.from_date(self, date_ish)
    end

    # @return [DateNamedFile::File] DateNamedFile::File for today/right now
    def now
      at DateTime.now
    end

    alias_method :today, :now

    # @return [DateNamedFile::File] DateNamedFile::File for tomorrow (+24 hours)
    def tomorrow
      at (DateTime.now + 1)
    end

    # @return [DateNamedFile::File] DateNamedFile::File for yesterday (-24 hours)
    def yesterday
      at (DateTime.now - 1)
    end

    # Get a list of computed files based on all the dates from the
    # given start through today, _including both ends_.
    # @param [<anything date_ish>] start_date_ish (see #forgiving_dateify)
    # @return [DateNamedFile::File] for tomorrow (+24 hours)
    def daily_since(start_date_ish)
      dt = forgiving_dateify(start_date_ish)
      if dt.to_date > DateTime.now.to_date
        []
      else
        daily_since(dt + 1).unshift(self.at(dt))
      end
    end

    # Like daily_since, but don't include today
    # @see #daily_since
    def daily_through_yesterday(date_ish)
      daily_since(date_ish)[0..-2]
    end

    # Like daily_since, but don't include the start date
    # @see #daily_since
    def daily_after(date_ish)
      daily_since(date_ish)[1..-1]
    end







  end
end
