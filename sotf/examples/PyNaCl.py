#!/usr/bin/env python

import base64, nacl.utils, zlib
from nacl.public import PrivateKey, Box

## Gen Bob Keys
me_priv_enc = PrivateKey.generate()
me_priv_clear = base64.b64encode(zlib.compress(str(me_priv_enc), 9))
me_pub_enc = me_priv_enc.public_key
me_pub_clear = base64.b64encode(zlib.compress(str(me_pub_enc), 9))

## Gen Alice Keys
you_priv_enc = PrivateKey.generate()
alice_priv_clear = base64.b64encode(zlib.compress(str(you_priv_enc), 9))
you_pub_enc = you_priv_enc.public_key
alice_pub_clear = base64.b64encode(zlib.compress(str(you_pub_enc), 9))

## Gen the box to send stuff in
# Bob must make a Box with his private key and Alice's public key
oBox = Box(me_priv_enc, you_pub_enc)

## Gen the nonce
nonce = nacl.utils.random(Box.NONCE_SIZE)

## Text Bob wants to encrypt
message = 'hello'

## Encrypt the text
enc_obj = oBox.encrypt(message, nonce)

## Send the text
IRC_text =  base64.b64encode(zlib.compress(enc_obj, 9))

## Turn the text into an object
Obj_To_Decrypt = zlib.decompress(base64.b64decode(IRC_text))

## Alice creates a box with her private key to decrypt the message
iBox = Box(you_priv_enc, me_pub_enc)

## Alice decrypts the text
decrypted = iBox.decrypt(enc_obj)




