# frozen_string_literal: true

require 'pathname'
require 'date_named_file/template'

module DateNamedFile

  class DatedFile < SimpleDelegator
    include Comparable

    attr_reader :datetime
    # @param [DateNamedFile::Template] template
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    def initialize(template, date_ish=DateTime.now)
      @template = template
      self.datetime = date_ish
    end

    def self.from_filename(template, filename)
      raise Error.new("String #{filename} does not match template '#{template.template_string}'") unless template.match? filename
      newobject = self.new(template)
      newobject.datetime = newobject.extract_datetime_from_filename(filename)
      newobject
    end

    # Defining to_datetime allows Dateish.forgiving_datetime to
    # deal with it directly
    def to_datetime
      self.datetime
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
      if self.match? other.to_s
        self.datetime <=> extract_datetime_from_filename(other)
      else
        d2 = Dateish.forgiving_dateify(other)
        z = self.datetime <=> d2
      end
    end

    def extract_datetime_from_filename(str)
      if m = @template.matcher.match(str)
        Dateish.forgiving_dateify(m[1..-1].join(''))
      else
        DateTime.new(0)
      end
    end

    def open
      raise "File #{@path.to_s} doesn't exist" unless @path.exist?
      begin
        Zlib::GzipReader.open(@path)
      rescue Zlib::GzipFile::Error
        File.open(@path)
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

  class OldDatedFile < SimpleDelegator

    attr_reader :embedded_date, :dft

    alias_method :template, :dft
    def initialize(dft, filename)
      @path = Pathname.new(filename)
      self.__setobj__ @path
      @dft = dft
      @embedded_date = dft.datetime_from_filename(@path.basename.to_s)
    end

    def self.from_filename(dft, filename)
      raise Error.new("String #{filename} does not match template '#{dft.template}'") unless dft.match? filename
      self.new(dft, filename)
    end

    def self.from_date(dft, date_ish)
      self.new(dft, dft.filename_for(date_ish))
    end

    def open
      raise "File #{@path.to_s} doesn't exist" unless @path.exist?
      begin
        Zlib::GzipReader.open(@path)
      rescue Zlib::GzipFile::Error
        File.open(@path)
      end
    end

    def ==(other)
      self.basename.to_s == other.basename.to_s
    end

    def to_s
      @path.to_s
    end

    def inspect
      "#<#{self.class.to_s}:#{@path} template=#{@dft.template}:#{object_id}>"
    end

    def pretty_inspect
      "#<#{self.class.to_s}: #{@path}\n  @template=#{@dft.template}\n  @embedded_date=#{@embedded_date.to_s}\n #{object_id}>"
    end

  end

end
