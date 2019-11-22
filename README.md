# DateNamedFile -- for files with embedded dates

## Usage

```ruby

require 'date_named_file'

update_file_template = DateNamedFile.new('hathi_upd_%Y%m%d.txt.gz')
update_files = update_file_template.in_dir('/tmp/')

update_files.at(20111122) #=> 

# Today is 2019-11-22


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
