# iOS Web Push Decryption Code #

This code is the client-side decryption code from the Toot! iOS client, which
uses the toot-relay web push proxy. It sets up keys and decrypts incoming
notifications relayed over APNS from the web push proxy.

The code should compile stand-alone, but may contain some Mastodon-specific
parts still. Use it as the basis of your own implementation!

This code includes a slightly edited copy of Luke Park's
[SwiftGCM code](https://github.com/luke-park/SwiftGCM) to handle aes-gcm
decryption.
