#!/usr/bin/python
'''
  This script is for decoding vigenere ciphers. Inspired by Mr Robot
  TriBeCa challenge from 2016.
  
  https://en.wikipedia.org/wiki/Vigenere_cipher

  - GI Jack, licensed under GPLv3. WIP
'''

import argparse
import string
import sys

ignore_chars = [""]

def message(message):
	print("vigenere.py:", message)

def exit_with_error(code,message):
    print("vigenre.py: ERROR:",message, file=sys.stderr)
    sys.exit(code)
    
def warn(message):
	print("vigenre.py: WARN:",message, file=sys.stderr)

def decode_vig(key,message):
    '''decode cypher with key. Return decoded text, takes a key and message as str'''
    message_lenth = 

def get_cmd_line_args():
	'''feed command line arguments through argparse '''
    parser = argparse.ArgumentParser(description='''Decode and bruteforce vigenere cipher'd text
    vigenere cipher:https://en.wikipedia.org/wiki/Vigenere_cipher ''',add_help=False)
    parser.add_argument("message",nargs='+',help="The Encoded Message")
    parser.add_argument("-?", "--help",  help="Show This Help Message", action="help")
    method = parser.add_mutually_exclusive_group()
    method.add_argument("-f", "-keyfile",help="Try all keys in specified text file. Use one key per line",type=str)
    method.add_argument("-k", "--key",   help="Decrypt the message with specified key",type=str)
    method.add_argument("-b", "--brute", help="Attempt to bruteforce the key",action="store_true")
    return parser

def main():
	cmdline_args = get_cmd_line_args()

if ___name___ == "___main___":
    main