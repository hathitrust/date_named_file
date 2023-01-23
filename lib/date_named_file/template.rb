# frozen_string_literal: true

require "date_named_file/dateish"
require "date_named_file/dated_file"

module DateNamedFile
  # A Template is a model of a filename with a (restricted but) valid
  # strftime formatting template embedded within.
  #
  # Basically, you can use
  # * %Y four=digit year
  # * %m two-digit month
  # * %d two-digit day
  # * %H two-digit hour 00-23
  # * %M minute
  # * %S second
  # * %s unix epoch time to the second
  # * %Q unix epoch time to the millisecond
  # * %1 arbitrary integer (for, e.g., log files. Not part of strftime)
  #
  # Examples:
  # * daily_update_%Y-%m-%d.txt
  # * mydaemon_%Y_%m_%d_%H%M.log
  # * updates%Y%m%d_dev.ndj.gz
  # * mylog%s.log
  #
  # In all cases date/time parts must be in order (year, month, day,
  # hour, minute, second).
  #
  # NO support for mixing unix epoch with anything else. Why would you do that?
  class Template
    include DateNamedFile::DateishHelpers

    SUBSTITUTION_REGEXP = {}
    SUBSTITUTION_REGEXP["%Y"] = '(\d{4})'

    %w[m d H M S].each { |x| SUBSTITUTION_REGEXP["%#{x}"] = '(\d{2})' }
    %w[s Q 1].each { |x| SUBSTITUTION_REGEXP["%#{x}"] = '(\d+)' }

    # @return [String] the initial template string
    attr_reader :template_string, :base_template

    # @return [Regexp] A regular expression that does its best to correctly match
    #   filenames that follow the template. Also used to try to extract the embedded
    #   date in a filename
    attr_reader :matcher

    # @param [String] template Template string with embedded strftime format string
    # @example
    #   tmpl = DateNamedFile::Template.new("mystuff_daily%Y%m%d.tsv")
    def initialize(template_string)
      @template_string = template_string
      @matcher = template_matcher(template_string)
      @base_template = self
    end

    # Test to see if a filename matches the template
    # @param [String] filename The string to test
    # @return [Boolean]
    def match?(filename)
      @matcher.match filename
    end

    def extract_datetime_from_filename(str = @path)
      if (m = @base_template.match?(str))
        Dateish.forgiving_dateify(m[1..].join(""))
      else
        DateTime.new(0)
      end
    end

    def file_from_filename(filename)
      raise Error.new("String #{filename} does not match template '#{template_string}'") unless @base_template.match? filename
      dt = extract_datetime_from_filename(filename)
      DatedFile.new(self).at(dt)
    end

    alias_method :matches?, :match?

    def in_dir(dir)
      DateNamedFile::Directory.new(self, dir)
    end

    # Compute the filename from plugging the given date_ish string/integer
    # into the template
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    # @return [String] the expanded filename
    def filename_for(date_ish)
      forgiving_dateify(date_ish).strftime(template_string)
    end

    # Get a DateNamedFile::File for the given date/datetime
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    # @return [DateNamedFile::File] DateNamedFile::File for the given date in this template
    def at(date_ish)
      DatedFile.new(self, date_ish)
    end

    alias_method :on, :at

    # @return [DateNamedFile::File] DateNamedFile::File for today/right now
    def now
      at DateTime.now
    end

    alias_method :today, :now

    # @return [DateNamedFile::File] DateNamedFile::File for tomorrow (+24 hours)
    def tomorrow
      at(DateTime.now + 1)
    end

    # @return [DateNamedFile::File] DateNamedFile::File for yesterday (-24 hours)
    def yesterday
      at(DateTime.now - 1)
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
        daily_since(dt + 1).unshift(at(dt))
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
      daily_since(date_ish)[1..]
    end

    def template_matcher(template)
      regexp_string = SUBSTITUTION_REGEXP.each_with_object(Regexp.escape(template)) do |subpair, templ|
        percent_escape, regex_replacement = *subpair
        templ.gsub!(percent_escape, regex_replacement)
      end
      Regexp.new(regexp_string)
    end
  end
end
