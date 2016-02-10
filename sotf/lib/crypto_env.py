class GPG_env:
	""" This class defines the GPG setup environment"""

	def env(self):
		"""Environment Setup"""
		import gnupg
		gLoc = raw_input('Use Native GPG environment location? [Y/n]\n')
		if (gLoc == 'y' or gLoc == 'Y' or not gLoc):
			from os.path import expanduser
			hDir = expanduser("~")
			hDir = '%s/.gnupg' % hDir
		else:
			hDir = raw_input('Desired Directory for GPG operations?\n')
			### Add some checks to make sure directory exists -- or make it here

		## See if the user has Safe version of gnupg
		try:
			gpg = gnupg.GPG(binary='/usr/bin/gpg', homedir=hDir, keyring='pubring.gpg', secring='secring.gpg')
		except:
			print '#############################################################'
			print '## WARNING                                                 ##'
			print '## INSECURE VERSION OF gnupg DETECTED                      ##'
			print '## CHECK OUT https://github.com/isislovecruft/python-gnupg ##'
			print '## apt-get purge python-gnupg && pip install gnupg         ##'
			print '##                                                         ##'
			print '## THIS VERSION MIGHT NOT ENCRYPT PROPERLY                 ##'
			print '## THIS VERSION IS SUSCEPTIBLE TO REMOTE CODE EXECUTION    ##'
			print '##                                                         ##'
			print '## CONTINUE AT YOUR OWN RISK                               ##'
			print '#############################################################'
			print ''
			gpg = gnupg.GPG(gpgbinary='/usr/bin/gpg', gnupghome=hDir, keyring='pubring.gpg', secret_keyring='secring.gpg')
		return gpg, hDir

class PyNaCl_env:
	"""This class defines the PyNaCl setup environment"""

	def env(self):
		"""Environment Checks"""
		try:
			from nacl.public import PrivateKey, PublicKey, Box
			import nacl.utils
		except:
			print 'Your PyNaCl environment is incorrect or non-existant'
			exit(1)