# faria_launchpad_api

This gem will help you to integrate your Ruby (or Ruby on Rails) application with Faria's [LaunchPad](https://dev.faria.co/launchpad/) platform.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faria-launchpad-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faria-launchpad-api


## Usage

### Generating a RSA public/private keypair

#### With the OpenSSL library inside Ruby

```ruby
# first setup a local keypair
key = OpenSSL::PKey::RSA.generate(2048)
File.open("./secure/private_key", "w") do |f|
  f.write(key.to_s)
end
# this is the public key LaunchPad needs
puts key.public_key.to_s
```

#### With the console OpenSSL tools

```bash
% openssl genrsa -out private_key.pem 2048
Generating RSA private key, 2048 bit long modulus
..+++
............................................+++
e is 65537 (0x10001)

% openssl rsa -pubout -in private_key.pem
writing RSA key
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6GUAjWeb1uyHJXhwBLtt
402PRlzHmMzK66b0Y+LKM789JaMO/8lOrCuoTtYkiWUpOU+7Qu6fBAMAGhCLYnOP
nMAftBbGN2Ppd64QYiAUTh/8pYtR36q88E7H74ngEHN/cBN8JXD4yqPo219/IyZs
uPIhJZgZ4DRGFanoilTYBOj8mH0hWVnFuwLrT6Qc0ibrIqyrQ4QP2NiM1CZlEO7t
lqJUm/bPgZdBqnQjbnfAmeyNRdsyeBhQvYhMLujdLpKQChYL64hAuj9X7ey8gZx5
rEaPECzlieoKcd3GL5KL+9g0vfvp8ZRyl54BgyDdS2P0p3r6xWqk/CTWjN+aAv/c
kQIDAQAB
-----END PUBLIC KEY-----
```


#### Serving your public key inside your application

The LaunchPad spec also requires that your web application serve this public key (text/plaintext) over HTTPs as part of the API your application must furnish to fully support LaunchPad.

    GET https://yourapplication.com/apis/launchpad/pubkey
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6GUAjWeb1uyHJXhwBLtt
    402PRlzHmMzK66b0Y+LKM789JaMO/8lOrCuoTtYkiWUpOU+7Qu6fBAMAGhCLYnOP
    nMAftBbGN2Ppd64QYiAUTh/8pYtR36q88E7H74ngEHN/cBN8JXD4yqPo219/IyZs
    uPIhJZgZ4DRGFanoilTYBOj8mH0hWVnFuwLrT6Qc0ibrIqyrQ4QP2NiM1CZlEO7t
    lqJUm/bPgZdBqnQjbnfAmeyNRdsyeBhQvYhMLujdLpKQChYL64hAuj9X7ey8gZx5
    rEaPECzlieoKcd3GL5KL+9g0vfvp8ZRyl54BgyDdS2P0p3r6xWqk/CTWjN+aAv/c
    -----END PUBLIC KEY-----

### Quick Usage Example

Here is a quick example. This example presumes you've already generated a 2,048 bit RSA keypair and your public key has been successfully connected with LaunchPad.


```ruby
    # fetch the LaunchPad public key 
    # (you should probably save it locally rather than constantly fetch it)
    uri = "https://devel.launchpad.managebac.com/api/v1/"
    launchpad_key = Net::HTTP.get_response(URI.parse(url + "pubkey")).body
    local_key = OpenSSL::PKey::RSA.new(File.read("./secure/private_key"))

    @service = Faria::Launchpad::Service.new(
      "https://devel.launchpad.managebac.com/api/v1/",
      {
        keys: { local: local_key, remote: launchpad_key },
        # the application name and URI issued to you during your 
        # LaunchPad setup process
        source: {
          name: "Acme Widgets, LLC.",
          uri: "https://app.acmewidgets.com/"
        }
      }
    )

    # simple ping
    puts service.ping()
    # debugging info
    puts service.info()
    # echos back whatever you send
    puts service.echo(name: "George Washington", age: 32)
```

The responses returned will almost always be JSON responses (see [API documentation](https://dev.faria.co/launchpad/) for additional details.)

### Rails Integration

There is a module to extend controllers to support easily handling incoming JWE requests and a Rails helper to assist with POSTing signed redirects.   Below is a usage example.

If the URL includes query parameters they will be stripped from the URL and encoded into the JWE as signed parameters.

The `SSO` module below is just one example of how you might wrap up all the pieces of a LaunchPad SSO configuration.  You might want to name this differently or pull settings from YAML, ENV, etc.  For the helpers to work you must call `launchpad_config` from your controller class and pass it an object that responds to `keys` and `source` and returns those settings.

```ruby
    module SSO
      def self.client
        Faria::Launchpad::Service.new(launchpad_uri,
          source: source,
          keys: keys
          )
      end

      def self.launchpad_uri
        "http://launchpad.dev/api/v1/"
      end

      def self.source
        @source ||= {
          name: "Lurn2Spell",
          uri: "http://lurn2spell.dev/launchpad/api/"
        }
      end

      def self.keys
        @keys ||= {
          local: OpenSSL::PKey::RSA.new(File.read('config/keys/local.priv')),
          remote: OpenSSL::PKey::RSA.new(File.read('config/keys/launchpad.pub'))
        }
      end
    end

    class YourController < ActionController::Base
      include Faria::Launchpad::Controller
      launchpad_config SSO
      
      def action
        post_encrypted_redirect_to SSO.client.pairing_request_url, 
          params_to_pass
      end
      
    end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eduvo/launchpad_api.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

