require 'minitest/autorun'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'srfax'

module SrFax
  # Override base URL for testing.
  # BASE_URL = 'https://httpbin.org/post'.freeze
end