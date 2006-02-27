#!/usr/local/bin/ruby
#
#            Tone Software Corporation BSD License ("License")
# 
#                        Software Build Environment
#                        
# Please read this License carefully before downloading this software. By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License. If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
# 
# A set of Jam configuration files and a Jam front-end for advanced
# software building with automatic dependency checking for the whole
# project. Provides a hierarchical project description while performing
# build procedures without changing directories. The resulting domain
# language changes emphasis from how to build to what to build. Provides
# separation of compilation artifacts (object files, binaries,
# intermediate files) from the original sources. Comes standard with
# ability to build programs, test suites, static and shared libraries,
# shared modules, code generation, and many others. Provides the bridge to
# ANT for building Java, with abilities to build JNI libraries.
# 
# Copyright (c) 2003, 2005, Tone Software Corporation
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer. 
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution. 
#   * Neither the name of the Tone Software Corporation nor the names of
#     its contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

require 'singleton'

module TSC
  class Netrc
    include Singleton

    private

    class Tokenizer
      def initialize(file)
	@file = file
	@tokens = []
      end

      def nextToken
	while @tokens.size == 0
	  @tokens = @file.readline.sub('#.*$','').split
	end
	return @tokens.shift
      end

      def nextLine
	@tokens = []
	_line = @file.readline
	return _line =~ /^\s*$/ ? nil : _line
      end
    end

    def saveEntry
      if @entry
	if @machine
	  @entries[@machine] = @entry
	else
	  @entries.default = @entry
	end
      end
      @entry = Hash.new
      @machine = nil
    end

    def parse
      begin
	_tokens = Tokenizer.new File.new("#{ENV['HOME']}/.netrc")

	@entries = Hash.new
	@entry = nil
	@machine = nil

	while true
	  _token = _tokens.nextToken
	  case _token
	    when 'machine'
	      saveEntry
	      @machine = _tokens.nextToken
	    when 'default'
	      saveEntry
	    when 'login', 'password', 'account'
	      @entry[_token] = _tokens.nextToken if @entry
	    when 'macdef'
	      while _tokens.nextLine
	      end
	    else
	  end
	end
      rescue EOFError
	saveEntry
      ensure
	@entry = nil
	@machine = nil
      end
    end

    def initialize
      parse
    end

    public

    def userinfo(machine)
      _entry = @entries[machine]
      if _entry
	return [ _entry['login'], _entry['password'], _entry['account'] ]
      end
      return [ nil, nil, nil ]
    end
    
    def userinfo?(machine)
      return @entries.key?(machine)
    end
  end
end

if __FILE__ == $0
  netrc = TSC::Netrc.instance

  puts "moose: #{netrc.userinfo?('moose').inspect}, #{netrc.userinfo('moose').inspect}"
  puts "bear: #{netrc.userinfo?('bear').inspect}, #{netrc.userinfo('bear').inspect}"

  _user, _passwd, _account = netrc.userinfo 'moose'
  puts "moose> USER: #{_user.inspect}, PASSWD: #{_passwd.inspect}, ACCOUNT: #{_account.inspect}"

  _user, _passwd, _account = netrc.userinfo 'bear'
  puts "bear> USER: #{_user.inspect}, PASSWD: #{_passwd.inspect}, ACCOUNT: #{_account.inspect}"
end

