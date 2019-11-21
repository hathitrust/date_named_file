require "date_named_file/version"
require 'date_named_file/template'

module DateNamedFile
  class Error < StandardError; end

  def self.new(*args, **kwargs)
    DateNamedFile::Template.new(*args, **kwargs)
  end

end
