# DateNamedFile -- for files with embedded dates

## Usage

```ruby

require 'date_named_file'

update_file_template = DateNamedFile.new('hathi_upd_%Y%m%d.txt.gz')
upd = update_file_template.in_dir('/tmp/')
#=> #<DateNamedFile::Directory:0x00007fa4105de1a0...>

# Today is 2019-11-22
# All of these will produce either a DatedFile, whether or not 
# it actually exists

# These are all the same
f = upd.yesterday
f = upd.at(:yesterday)
f = upd.at(20191121)
f = upd.at('2019-11-21')
f = upd.at('2019_11_21')
f = upd.at('11/21/2019')
f = upd.at(-1)

#=> <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191121.txt.gz>

# Yesterday's file is there
f.exist? #=> true

# ...but today's is not
upd.today #=>  <DateNamedFile::MissingFile:/private/tmp/hathi_upd_20191122.txt.gz>
upd.today.exist? #=> false

# So, which ones are there?
 upd.matching_files
# => [<DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191118.txt.gz>,
 #    <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191119.txt.gz>,
 #    <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191120.txt.gz>,
 #    <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191121.txt.gz>]

# A DateNamedFile::Directory is enumerable

upd.each { ... }
f = upd.first #=> <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191118.txt.gz>

# Let's get everything since the 20th

upd.since '2019-11-20' #or 
upd.since -2
# => [<DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191120.txt.gz>,
#     <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191121.txt.gz>]



# A DatedFiles compares based on the embedded DateTime
upd.at('2019-11-11') > upd.at('2019-11-10') #=> true

# ..even across different templates and embedded date formats
full_files = DateNamedFile.new('hathi_full_%Y-%m-%d.txt').in_dir('/tmp')

last_update = upd.last #=> <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191121.txt.gz>
last_full  = full.last #=> <DateNamedFile::DatedFile:/private/tmp/hathi_full_2019-11-20.txt.gz>

last_update > last_full #=> true

# A DatedFile delegates most things to a Pathname object
last_update.ctime # => 2019-11-22 14:22:49 -0500
last_update.basename('.gz') #=> #<Pathname:hathi_upd_20191121.txt>

#...but we override #open to automatically deal with .gz files
# if need be

last_update #=> <DateNamedFile::DatedFile:/private/tmp/hathi_upd_20191121.txt.gz>
last_update.open.first #=> "mdp.39015018415946\tdeny\t..."


# Can read or write to a file, with optional block

new_path = upd.today
new_path.exit? #=> false
new_path.open_for_write do |out|
  out.puts "Hey there!"
end


```




## Installation

Add this line to your application's Gemfile:

```ruby
gem 'date_named_file'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install date_named_file

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/billdueber/date_named_file.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
