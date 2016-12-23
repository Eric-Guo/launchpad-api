require 'test_helper'
require 'pry'
require 'pry-byebug'

class Faria::Launchpad::PacketTest < Minitest::Test
  def acme_key
    @acme_key ||= begin
      local_key = File.read('./test/keystore/keys/Acme.priv')
      OpenSSL::PKey::RSA.new(local_key)
    end
  end

  def launchpad_key
    @launchpad_key ||= begin
      launchpad_key = File.read('./test/keystore/keys/Launchpad.priv')
      OpenSSL::PKey::RSA.new(launchpad_key)
    end
  end

  def test_encrypt_decrypt_cycle
    data = { test: 'Hello' }
    secret_stuff = Faria::Launchpad::Packet.encrypt(data, {}, local_key: acme_key, remote_key: launchpad_key.public_key)

    result = Faria::Launchpad::Packet.decrypt(secret_stuff, {}, local_key: launchpad_key, remote_key: acme_key.public_key)
    assert_equal data[:test], result['test']
  end


  def test_decrypt_variable_key
    skip
  end

end
