# frozen_string_literal: true

require "pathname"
require "delegate"
require "zinzout"
require "date_named_file/template"

module DateNamedFile
  class DatedFile < SimpleDelegator
    include Comparable

    attr_reader :datetime
    # @param [DateNamedFile::Template] template
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    def initialize(template, date_ish = DateTime.now)
      @template = template
      self.datetime = date_ish
    end

    def self.from_filename(template, filename)
      raise Error.new("String #{filename} does not match template '#{template.template_string}'") unless template.match? filename
      newobject = new(template)
      newobject.datetime = newobject.extract_datetime_from_filename(filename)
      newobject
    end

    # Defining to_datetime allows Dateish.forgiving_datetime to
    # deal with it directly
    def to_datetime
      datetime
    end

    def datetime=(date_ish)
      @datetime = Dateish.forgiving_dateify(date_ish)
      @path = Pathname.new(@template.filename_for(@datetime).to_s)
      __setobj__ @path
    end

    def match?(other)
      @template.match? other.to_s
    end

    def <=>(other)
      if match? other.to_s
        datetime <=> extract_datetime_from_filename(other)
      else
        d2 = Dateish.forgiving_dateify(other)
        datetime <=> d2
      end
    end

    def extract_datetime_from_filename(str)
      if (m = @template.matcher.match(str))
        Dateish.forgiving_dateify(m[1..].join(""))
      else
        DateTime.new(0)
      end
    end

    def open
      raise "File #{@path} doesn't exist" unless @path.exist?
      f = Zinzout.zin(@path)
      if block_given?
        yield f
        f.close
      else
        f
      end
    end

    # The old "open" is fine, but add this for parallel naming
    # with #open_for_write
    alias_method(:open_for_read, :open)

    def open_for_write
      f = Zinzout.zout(@path)
      if block_given?
        yield f
        f.close
      else
        f
      end
    end

    # Override pretty-print so it shows up correctly in pry
    def pretty_print(q)
      q.text "<#{self.class}:#{@path}>"
    end
  end

  class MissingFile < DatedFile
    def exist?
      false
    end

    alias_method :exists?, :exist?
  end
end
