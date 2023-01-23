# frozen_string_literal: true

require "pathname"
require "date_named_file/template"
require "date_named_file/dated_file"

module DateNamedFile
  # The instantiation of a template over a specific directory. This allows
  # us to find out which files that match the template actually exist,
  # extract dates from them, etc.
  class Directory < DateNamedFile::Template
    include Enumerable
    # @return [Pathname]
    attr_accessor :dir_path, :matching_files

    # @param [DateNamedFile::Template] template The file template
    # @param [Pathname, String] path The path to the directory
    def initialize(template, path)
      @dir_path = Pathname.new(path).realdirpath
      raise ArgumentError.new("Directory '#{path}' does not exist") unless @dir_path.exist?
      raise ArgumentError.new("'#{path}' isn't a directory") unless @dir_path.directory?
      super((@dir_path + template.template_string).to_s)
      @matching_files = @dir_path.children.sort.select { |x| match? x.to_s }.map { |x| DatedFile.from_filename(self, x.to_s) }
    end

    def since(date_ish)
      self.select { |f| f >= date_ish }
    end

    def after(date_ish)
      self.select { |f| f > date_ish }
    end

    def last
      @matching_files.last
    end

    # Does this directory have a file for the given date?
    # @param [<anything date_ish>] date_ish (see #forgiving_dateify)
    # @return [Boolean]
    def has_file_for_date?(date_ish)
      target = no_existence_check_at(date_ish)
      (@dir_path + target).exist?
    end

    alias_method :has?, :has_file_for_date?

    # Yield matching files for each
    def each
      return enum_for(:each) unless block_given?
      @matching_files.each { |f| yield f }
    end
  end
end
