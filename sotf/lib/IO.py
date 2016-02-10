class GPG_IO:
	"""This class is used for parsing input/output for GPG"""

	def irc_in(self, gpg, text, hdr, gPass = None):
		"""Parses pasted inbound messages from IRC"""
		print text
		iPut = ""
		EOF = ""
		while True:
			line = raw_input()
			if line.strip() == EOF:
				break
			iPut += "%s\n" % line.split('> ')[1:]
		return str(iPut.replace('[', '').replace(']', '').replace('\'', '').replace('*-', '%s' % hdr))

	def shell_in(self, gpg, text, gPass = None):
		"""Parses inbound messages from shell"""
		print text
		iPut = ""
		EOF = '***'
		while True:
			line = raw_input()
			if line.strip() == EOF:
				break
			iPut += "%s\n" % line
		return str(iPut) 

	def out(self, gpg, you, text):
		"""Encrypts outbound messages for IRC"""
		print text
		iPut = ""
		EOF = ""
		while True:
			line = raw_input()
			if line.strip() == EOF:
				break
			iPut += "%s\n" % line
		return gpg.encrypt(str(iPut), you, hidden_recipients = you)


class PyNaCl_IO:
	"""This class is used for parsing input/output for PyNaCl"""

	def irc_in(self, text):
		"""Decrypts inbound messages from IRC"""
		import base64, zlib
		print text
		iPut = ""
		EOF = ""
		while True:
			line = raw_input()
			if line.strip() == EOF:
				break
			iPut += "%s\n" % line.split('> ')[1:]
		return zlib.decompress(base64.b64decode(str(iPut.replace('[', '').replace(']', '').replace('\'', ''))))

	def shell_in(self, text):
		"""Parses inbound messages from shell"""
		import base64, zlib
		print text
		iPut = ""
		EOF = ''
		while True:
			line = raw_input()
			if line.strip() == EOF:
				break
			iPut += "%s\n" % line
		return zlib.decompress(base64.b64decode(str(iPut)))

	def out(self, myBox, text):
		"""Encrypts outbound messages for IRC"""
		import nacl.utils
		from nacl.public import Box
		nonce = nacl.utils.random(Box.NONCE_SIZE)
		print text
		iPut = ""
		EOF = ""
		while True:
			line = raw_input()
			if line.strip() == EOF:
				break
			iPut += "%s\n" % line
		return myBox.encrypt(iPut, nonce)
