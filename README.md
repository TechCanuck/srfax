Srfax

This is the 'unofficial' SRFax (http://www.srfax.com) API wrapper for ruby.  The API documentation for SRFax can be found at https://www.srfax.com/srf/media/SRFax-REST-API-Documentation.pdf

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sr_fax'
```

And then execute:

    $ bundle

Or install it yourself using:

    $ gem install sr_fax

## Usage

To get started, simply open the console view and require the SrFax module.  Once you have completed that, enter your account credentials using the SrFax setup block, and then begin to execute calls. All status' returned are simply formatted hashes from the SrFax service.

```ruby

require 'srfax'

SrFax.setup do |config|
  config.defaults[:access_id] = '1234'
  config.defaults[:access_pwd] = 'password'
  config.connection_defaults[:timeout] = 180
end

SrFax.view_inbox
SrFax.view_outbox
SrFax.update_fax_status(descriptor, direction)
SrFax.get_fax(descriptor, direction, {:sMarkasViewed => 'Y'}
```

As an example, here is a sample queue fax call to send a fax

```ruby
SrFax.queue_fax "yourname@yourdomain.com", "SINGLE", "18888888888", {sFileName_1: "file1.txt", sFileContent_1: Base64.encode64("Sample Fax")}
```

The SrFax module currently supports the following functions
  - Sending and receiving faxes
  - Updating flags on the inbox or outbox faxes
  - Deleting faxes from either the inbox or outbox
  - View account usage
  - Download faxes from the inbox or outbox

## Development

After checking out the repo, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/TechCanuck/srfax/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Licensing: **MIT**
Remember: **'Great opportunities to help others seldom come, but small ones surround us daily' -- Sally Koch**
