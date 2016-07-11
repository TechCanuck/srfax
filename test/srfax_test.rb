require File.join(File.expand_path(File.dirname(__FILE__)), 'test_helper')

class TestSrFax < Minitest::Test

  def setup
  end

  def test_queue_fax
    response = SrFax.queue_fax(
      'test@test.com',
      '5555555555',
      'SINGLE',
      sFileName_1: 'test.pdf',
      sFileContent_1: Base64.encode64(File.read(File.join(File.expand_path(File.dirname(__FILE__)), 'test.pdf')))
    )
    assert_equal response, { "Status" => "Failed", "Result" => "Invalid Access Code / Password" }
  end

end