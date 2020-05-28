#!/usr/bin/env python
import commands
import sys
import urllib
import os
from xml.dom.minidom import parse, parseString

VERSION = '1.0'

DRIVE_ROOT = 'https://drive.corp.amazon.com:443/mnt/'
DRIVE_SCRIPT_HOME = '/Drive CLI Client/drive.py'

def execute(cmd):
	status,output = commands.getstatusoutput(cmd)
	if status != 0:
		raise Exception(output)
	return output

def curl(url, verb='', options=''):
	command = "kcurl -sS --negotiate -u : -f -k -X %s %s '%s'" % (verb, options, DRIVE_ROOT+urllib.quote(url))
	try:
		# Try to curl with kerberos negotiation
		return execute(command)
	except Exception, e:
		if not str(e).strip().endswith('401'): raise
		# Raise exceptions for non-tty work becuase stdin will swallow any password prompts.
		if not sys.stdin.isatty(): raise
		try:
			# Try and execute a kinit
			print 'Trying kinit'
			if os.system('kinit') != 0: raise Exception('401')
			return execute(command)
		except Exception, e1:
			if not str(e).strip().endswith('401'): raise
			print 'Falling back to BasicAuth'
			import getpass
			# Didn't work, try manually passing username and let user type password
			user = os.environ['USER']
			password = getpass.getpass('Enter password for "%s":' % (user))
			command = "curl -sS -f -u %s:%s -k -X %s %s '%s'" % (user, password, verb, options, DRIVE_ROOT+urllib.quote(url))
			return execute(command)


def download(what, where):
	if not what: usage()
	if not where: where = what.split('/')[-1]
	curl(what, options="-o '%s'" % (where), verb='GET')


def upload(what, where):
	if not where and what: usage()
	curl(os.path.dirname(where)+'/', options="-T '%s'" % (what), verb='PUT')

def mkdir(where):
	if not where: usage()
	curl(where, verb='MKCOL')

def listdir(where):
	if not where: usage()
	options = """-H "Content-Type:text/xml" -H "Depth: 1" -d "<?xml version='1.0'?><a:propfind xmlns:a='DAV:'><a:prop><a:getcontenttype/></a:prop><a:prop><a:getlastmodified/></a:prop><a:prop><a:getcontentlength/></a:prop></a:propfind>" """
	xml = curl(where, verb='PROPFIND', options=options)
	xml = parseString(xml)
	if sys.stdout.isatty():
		print 'Type'.ljust(30), 'Date Modified'.ljust(40), 'File size'.ljust(20), 'Path'
	else:
		pass
	print '-'*100
	for child in xml.childNodes[0].childNodes:
		url = child.getElementsByTagName('D:href')[0].childNodes[0].data
		props = child.getElementsByTagName('D:prop')[0]
		content_type = props.getElementsByTagName('D:getcontenttype')[0].childNodes[0].data
		date_modified = props.getElementsByTagName('D:getlastmodified')[0].childNodes[0].data
		size = props.getElementsByTagName('D:getcontentlength')[0].childNodes[0].data
		path = url[len(DRIVE_ROOT):]
		if sys.stdout.isatty():
			print content_type.ljust(30), date_modified.ljust(40), size.ljust(20), path
		else:
			print path

def usage():
	print """drive [download|upload|mkdir|list] <what> <where>"""
	sys.exit(1)

verbs = {
	'help': ('-h', '--h', 'help', 'h'),
	'download': ('-down', '-d', 'down', 'd', 'download'),
	'upload': ('-up', '-u', 'u', 'up', 'upload'),
	'list': ('-ls', 'ls', '-l', 'l', 'list'),
	'mkdir': ('-mk', 'mk', '-m', 'm', 'mkdir'),
	'install': ('install'),
	'update': ('update'),
	'version': ('-v', 'version')
}

def update():
	script_path = os.path.realpath(__file__)
	script = open(script_path, 'r')
	first_line = script.readline()
	script.close()
	curl(DRIVE_SCRIPT_HOME, options="-o '%s'" % ('.drive.py'), verb='GET')
	script = open('.drive.py', 'r')
	script_contents = script.read()
	script.close()
	assert script_contents.split('\n')[0].strip() == first_line.strip()
	script = open(script_path, 'w')
	script.write(script_contents)
	script.close()

def install(where):
	# Read this script into memory
	script = os.path.realpath(__file__)
	script = open(script, 'r')
	script_contents = script.read()
	script.close()	
	# Try to autodetect where to install.... Somewhere "usr" "bin"'sh that isn't 
	if where == None:
		paths = os.environ['PATH']
		paths = paths.split(':')
		install_path = None
		for path in paths:
			if 'usr' in path and 'bin' in path:
				install_path = path
				break
	else: install_path = where
	if install_path == None: raise Exception()
	script_path = os.path.join(install_path, 'drive.py')
	script = open(script_path, 'w')
	script.write(script_contents)
	script.close()
	execute("chmod +x '%s'" % (script_path))
	for cmd in ('drive-up', 'drive-down', 'drive-mkdir', 'drive-ls' ,'drive'):
		execute("ln -sf '%s' '%s'" % (script_path, os.path.join(install_path, cmd)))
	

def version():
	print VERSION

def cmd():

	argv0 = sys.argv[0]
	argv0 = os.path.basename(argv0)

	if argv0.startswith('drive-'):
		if len(sys.argv) < 1: usage()
		sys.argv[0] = argv0[len('drive-'):]
		args = sys.argv[1:]+[None, None, None, None, None]
		verb  = sys.argv[0]		
	else:
		if len(sys.argv) < 2: usage()
		args = sys.argv[2:]+[None, None, None, None, None]
		verb  = sys.argv[1]

	if verb in verbs['help']:
		usage()
	if verb in verbs['download']:
		download(args[0], args[1])
	elif verb in verbs['upload']:
		upload(args[0], args[1])
	elif verb in verbs['list']:
		listdir(args[0])
	elif verb in verbs['mkdir']:
		mkdir(args[0])
	elif verb in verbs['install']:
		install(args[0])		
	elif verb in verbs['update']:
		update()
	elif verb in verbs['version']:
		version()	
	else:
		usage()


cmd()
