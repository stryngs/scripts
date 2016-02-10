class GPG_chat:
	"""This class defines how we chat using GPG"""

	def gpg(self, gpg, mode, you, me, gPass, mLen):
		"""Encrypt or Decrypt"""
		from lib.IO import GPG_IO
		dCrypt = GPG_IO()
		eCrypt = GPG_IO()
		gChoice = raw_input('[E]ncrypt or [D]ecrypt\n')
		print ''
		if (gChoice == 'E' or gChoice == 'e'):
			if (mode == '-i' or not mode):
				## Shorten the encrypted GPG
				encrypted = eCrypt.out(gpg, you, 'Enter GPG message to encrypt\nUse a blank line for EOF')
				encrypted = str(str(encrypted).split('-----BEGIN PGP MESSAGE-----')[1:])
				encrypted = '*-%s' % str(encrypted.replace('[', '').replace(']', '').replace('\'', '').replace('\\n', '').replace('-----END PGP MESSAGE-----', '-*'))

				## Split the string into a list based on mLen
				sList = [encrypted[i:i+mLen] for i in range(0, len(encrypted), mLen)]
				print 'Your message:\n'
				for i in sList:
					print i
				print ''
			else:
				print 'Your message:\n%s' % eCrypt.out(gpg, you, 'Enter GPG message to encrypt\nUse a blank line for EOF')
				print ''

		elif (gChoice == 'D' or gChoice == 'd'):
			if (mode == '-i' or not mode):
				encrypted = dCrypt.irc_in(gpg, 'Enter GPG message to decrypt\nUse a blank line for EOF', '-----BEGIN PGP MESSAGE-----\n\n', gPass)
			else:
				encrypted = dCrypt.shell_in(gpg, 'Enter GPG message to decrypt\nUse *** for EOF')
			print 'Your message:\n%s\n' % str(gpg.decrypt(encrypted, passphrase = gPass))


class PyNaCl_chat:
	"""This class defines how we chat using PyNaCl"""

	def pynacl(self, myBox, mode, privObj, partner_enc, mLen):
		import base64, zlib
		from lib.IO import PyNaCl_IO
		eCrypt = PyNaCl_IO()
		dCrypt = PyNaCl_IO()
		gChoice = raw_input('[E]ncrypt or [D]ecrypt\n')
		if (gChoice == 'E' or gChoice == 'e'):
			eObj = eCrypt.out(myBox, '\nEnter PyNaCl message to encrypt\nUse a blank line for EOF')
			if (mode == '-i' or not mode):
				encrypted = base64.b64encode(zlib.compress(eObj, 9))
				
				## Split the string into a list based on mLen
				sList = [encrypted[i:i+mLen] for i in range(0, len(encrypted), mLen)]
				print 'Your message:\n'
				for i in sList:
					print i
				print ''
			else:
				print 'Your message:\n%s\n' % base64.b64encode(zlib.compress(eObj, 9))

		elif (gChoice == 'D' or gChoice == 'd'):
			if (mode == '-i' or not mode):
				encrypted = eCrypt.irc_in('\nEnter PyNaCl message to decrypt\nUse a blank line for EOF')
			else:
				encrypted = eCrypt.shell_in('\nEnter PyNaCl message to decrypt\nUse a blank line for EOF')
			print 'Your message:\n%s' % myBox.decrypt(encrypted)
