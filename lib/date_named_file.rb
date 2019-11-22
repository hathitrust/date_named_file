require "date_named_file/version"
require 'date_named_file/template'
require 'date_named_file/directory'
require 'date_named_file/dated_file'

module DateNamedFile
  class Error < StandardError; end

  def self.new(*args)
    DateNamedFile::Template.new(*args)
  end

end
