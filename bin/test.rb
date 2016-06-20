#!/usr/bin/env ruby

require "bundler/setup"
require "faria/launchpad/api"
require "faria/launchpad/packet"
require "faria/launchpad/service"

require 'jwt'

# local development key
local_key = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA7/fDPYs386BH+EcajZLZ/KypIi20ZqNOhqM4MZj+qccZSjxi
1jxBb9cbnYPBHLJz7Bng7PpeekarseEs5k3mN6c/HG65DIEAO4PeOVY7eDzATA6N
U0PE+zjF3pfrqKGyATNXyUILnEis5YuYwlRr6Bn5XNdSfqTJv0vuovLmY7NQsylP
920dKxvdpiK5ASFAFPjA0TNEPAPMNEq1D/ewljHAkMOmmrNZbmtXbmvOro5CAgQN
iOGGd+sazkc77ncIvFi6k4iY3k8DKyF6CnIfi/2SlaxNmiKs2lW4CUSyd1/w1mmO
xaBVnDUt1BXQzLD8AKsTSYyLAOdEqsyOdBnlAQIDAQABAoIBAQCkOYiZbtSM241F
gcvPRcf/X16ksGi8sViFVeCYON9X65UINAlkGnqiArG4e7nGXO5uj0tagwHzZrgM
FVF4D6nVPpU3bSMhRouVL2r/DF/IqrLjmjXn3QJK95CbBJdXoclDfxK9/oAZpbcF
pSKXI9VxU41Pl2CyoS4cx+d6BwfbBEKRwX24VxUR8ECiPTLBmWgzzcezh/2zIF+t
F/5ZP3jMICxNHgD4R6lUB+hBhgLJ3NI9IkA1TgkLvJJoMl5x5+XvR06by4OoQT94
NLM/aG/Q0nqp20CT8H0KG/tR6ZHsJR5lK6ru5YLr/me/n7ChlpZkrE29MzfiVqWE
cpXA+QbNAoGBAPxOq791We2vGYgQ6zylS3uf5E+i5Jn0LAJMGLcoXx0oQgHoMMW2
MP7rVA/q5GAkDFb8aZ0pMWWcltZQLCHXrDPgDW7B/poGB26Kj451448pvauZ+A7g
2pC92h99G2N+uC+MK3IIdwvgPxffcO4OQCtbF/wMziyF9TrXeR1u7AtfAoGBAPN6
2+T2JNlHkeBOz+gVPXwZOAQQNj1+x6vIyvyOZsOGiv6BEAy+cjD75Rm9lk30vMPH
9krdX0ImzjDXjcvW4s4bcZch11m+IIeK2dR/VNh3SW53kbu2ONAklP+xjEnF7Jrh
coDicSfjzjOCqaraBnHeEm3eAYmvXlPNuGZSFkufAoGAIxRtHLmcP0fRLPHtQwlY
bV/VxpzHXABu/gLGjPC4CL3IL6uw3Exwk4D0tyHZjuR0MsP1izxm+dHDxxhuimYK
M0w7keK3G4MrFVt+ijgp44XSMUG/E5J/0RAUe7xRSowb38CFad1zb9tF6nPOp8qj
cWPA+fJt2BLn/b5nwIfjmdECgYAoP/0uAorg6HXzENRJ14kMhNa/xTZSQC0d9tmn
mpreY9WCcS+IC8uw0VN0R+UbCgRSkTHj+miO9P9ND7U/J0zjKaJDi7KgAVA7V/be
rBYImt+mxVlwIJWPwxxmkKFSaMfOasqVB9oQ8BXcahNGTTiXhlChnPvAGR+M1wtO
zu8knQKBgQDTKR+8k5/IDlXuxKbT1Xf86aNRtKH4uAZmGlnTJMtapjMuy4I/I0Ck
ZAutRaDr1pYfdfXhZY2Mai/XfRjMAFP2Gd7Iiu3mtpoyj4RGVYjtRHtMp7uTux6z
PtfMDOAgkGltiKlU7SnHSULoDYutQOIn/lux53rooRjxlTe0sBoLgg==
-----END RSA PRIVATE KEY-----"

local_key = OpenSSL::PKey::RSA.new(local_key)

# get our local copy for testing
lp_key = File.read("../launchpad/config/keystore/keys/Launchpad.priv")
lp_key = OpenSSL::PKey::RSA.new(lp_key).public_key

service = Faria::Launchpad::Service.noauth("http://launchpad.dev/api/v1/")

puts '/ping'
puts service.ping
puts '/pubkey'
puts service.pubkey

service = Faria::Launchpad::Service.new(
  "http://launchpad.dev/api/v1/",
  {
    keys: { local: local_key, remote: lp_key },
    # consumer_name: "Demo 3rd party",
    source: {
      name: "Finalsite",
      uri: "https://faria.finalsite.com/"
    }
  }
)


puts "/info"
puts service.info()
puts "/echo"
puts service.echo(name: "George Washington", age: 32)
puts "/client_applications"
puts service.get("client_applications")
puts "/identities"
puts service.get("identities")


service = Faria::Launchpad::Service.new(
  "http://launchpad.dev/api/v1/",
  {
    keys: { local: local_key, remote: lp_key },
    # consumer_name: "Demo 3rd party",
    source: {
      name: "Finalsitez",
      uri: "https://faria.finalsite.com/"
    }
  }
)

puts "/info"
puts service.info()
