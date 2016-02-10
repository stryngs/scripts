class GPG_keys:
	""" This class defines how we handle keys for GPG"""

	def key_export(self, gpg, tKey, mLen):
		"""Deal with irssi style key exports"""
		encrypted = gpg.export_keys(tKey)
		encrypted = str(str(encrypted).split('-----BEGIN PGP PUBLIC KEY BLOCK-----')[1:])
		encrypted = '*-%s' % str(encrypted.replace('[', '').replace(']', '').replace('\'', '').replace('\\n', '').replace('-----END PGP PUBLIC KEY BLOCK-----', '-*'))

		## Split the string into a list based on mLen
		sList = [encrypted[i:i+mLen] for i in range(0, len(encrypted), mLen)]
		print '\nExported key:'
		for i in sList:
			print i

	def key_show(self, gpg):
		### Need to deal with same fingerprints issue Jack64 brought up here...
		gKeys = gpg.list_keys()
		kLength = len(gKeys.uids)
		count = 0
		while count < kLength:
			print '%s : %s' % (gKeys.uids[count], gKeys.fingerprints[count])
			count += 1

	def key_select(self, gpg, mode, mLen):
		"""Obtain keys to work with"""
		from lib.keys import GPG_keys
		from lib.IO import GPG_IO
		from getpass import getpass
		dCrypt = GPG_IO()
		GPG = GPG_keys()
		gpg.encoding = 'utf-8'
		iKey = raw_input('Are we importing a public key? [y/N]\n')
		if (iKey == 'n' or iKey == 'N' or not iKey):
			pass
		else:
			if (mode == '-i' or not mode):
				iKey = dCrypt.irc_in(gpg, 'Enter Public Key to Import\nUse a blank line for EOF', '-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n')
			else:
				iKey = dCrypt.shell_in(gpg, 'Enter Public Key to Import\nUse *** for EOF')
			gpg.import_keys(iKey)

		eKey = raw_input('Are we exporting a public key? [y/N]\n')
		if (eKey == 'n' or eKey == 'N' or not eKey):
			pass
		else:
			GPG.key_show(gpg)
			tKey = raw_input('\nEnter Public Key to Export\n')
			if (mode == '-i' or not mode):
				IRC = GPG_keys()
				IRC.key_export(gpg, tKey, mLen)
			else:
				exp = gpg.export_keys(tKey)
				print '\nExported key:\n%s' % exp
			print '\n'

		GPG.key_show(gpg)
		you = raw_input('\nPublic Key ID of Chat Partner?\n')
		print ''
		me = raw_input('Private Key ID?\n')
		print ''
		gPass = getpass('Private Key Password?\n')
		print ''
		return you, me, gPass


class PyNaCl_keys:
	""" This class defines how we handle keys for PyNaCl"""
	def key_exp(self, privObj):
		"""Generate a public key"""
		import base64, zlib
		from nacl.public import PrivateKey
		try:
			pubObj = privObj.public_key
			return base64.b64encode(zlib.compress(str(pubObj), 9))
		except:
			print 'You must generate a private key first'

	def key_gen(self):
		"""Generate a private key"""
		import base64, zlib
		from nacl.public import PrivateKey
		privObj = PrivateKey.generate()
		privKey = base64.b64encode(zlib.compress(str(privObj), 9))
		return privObj, privKey

	def key_imp(self):
		"""Allows for the importing of a PyNaCl style key"""
		from getpass import getpass
		from lib.crypto_env import GPG_env
		cType = GPG_env()
		gpg, hDir = cType.env()
		pPass = getpass('Private Key Password?')
		with open('%s/pKey.gpg' % hDir, 'r') as key:
			pObj = gpg.decrypt_file(key, passphrase = pPass)
		return pObj.data

	def key_save(self, privKey):
		"""Allows for the saving of a PyNaCl style key"""
		import os.path
		from getpass import getpass
		from lib.crypto_env import GPG_env
		cType = GPG_env()
		gpg, hDir = cType.env()

		## Ensure we aren't overwriting a previous key...
		if os.path.isfile('%s/pKey.gpg' % hDir):
			print '%s/pKey.gpg currently exists!\nPlease rename or move this key before continuing\n' % hDir
			exit(1)
		else:
			pPass = getpass('Private Key Password?\n')
			foo = gpg.encrypt(privKey, armor = False, encrypt = False, output = '%s/pKey.gpg' % hDir, passphrase = pPass, symmetric = True)

	def key_select(self):
		"""Environment Setup"""
		import base64, nacl.utils, zlib
		from lib.keys import PyNaCl_keys
		from nacl.public import PrivateKey, PublicKey, Box
		pynacl = PyNaCl_keys()
		kChoice = raw_input('[G]enerate a Private Key or [I]mport a Private Key?\n')
		if (kChoice == 'g' or kChoice =='G'):
			privObj, privKey = pynacl.key_gen()
			kSave = raw_input('\nSave the key? [y/N]\n')
			if (kSave == 'y' or kSave =='Y'):
				print ''
				pynacl.key_save(privKey)
			print '\nYour Public Key is:\n%s' % pynacl.key_exp(privObj)
		elif (kChoice == 'i' or kChoice =='I'):
			print ''
			from lib.crypto_env import GPG_env
			cType = GPG_env()
			plainKey = pynacl.key_imp()
			plainObj = zlib.decompress(base64.b64decode(plainKey))
			privObj = PrivateKey(plainObj)
			print '\nYour Public Key is:\n%s' % pynacl.key_exp(privObj)

		## Import partner public key
		partner_plain = raw_input('\nEnter Plaintext Public Key of Chat Partner:\n')
		print ''
		
		## Can probably enclose this within PublicKey()
		partner_obj = zlib.decompress(base64.b64decode(partner_plain))
		partner_enc = PublicKey(partner_obj)

		## Create a box for chat
		return Box(privObj, partner_enc), privObj, partner_enc
