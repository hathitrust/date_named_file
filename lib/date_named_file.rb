require "date_named_file/version"
require "date_named_file/template"
require "date_named_file/directory"
require "date_named_file/dated_file"

module DateNamedFile
  class Error < StandardError; end

  def self.new(template_string, dir = nil)
    t = DateNamedFile::Template.new(template_string)
    if dir
      t.in_dir(dir)
    else
      t
    end
  end
end
