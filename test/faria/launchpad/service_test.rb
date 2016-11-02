require 'test_helper'

class Faria::Launchpad::ServiceTest < Minitest::Test
  def setup
    @service = Faria::Launchpad::Service.new('http://localhost:3000/api/v1',{keys: {}, source: {}})
  end
  def test_import_identities
    @service.stub(:post, {'status' => 'success', 'data' => nil }) do
      result = @service.import_identities('test-api', [1, 2, 3])
      assert_equal(result['status'], 'success')
    end
  end
end
