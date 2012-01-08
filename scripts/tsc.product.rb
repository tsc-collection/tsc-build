#!/usr/bin/env ruby

=begin
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
=end

require 'singleton'
require 'English'

require 'tsc/platform'
require 'tsc/config'
require 'tsc/dtools'

require 'tsc/perforce/commander'

module TSC
  class Product
    attr_reader :name, :product, :release, :build, :topdir, :platform
    attr_reader :library_major, :library_prefix
    attr_reader :handoff_server, :handoff_recepients

    include Singleton

    def self.detect
      instance
    end

    def initialize
      check_top
      obtain_product_info
    end

    def prodinfo
      "#{topsrc}/project/config/product.info"
    end

    def topsrc
      "#{@topdir}/src"
    end

    def topbin
      "#{@topdir}/bin"
    end

    def topdst
      "#{@topdir}/dst"
    end

    def toppkg
      "#{@topdir}/pkg"
    end

    def topget
      "#{@topdir}/gen"
    end

    def repository_build
      obtain_build_from_repository
    end

    private
    #######
    def p4
      @p4 ||= TSC::Perforce::Commander.new
    end

    def check_top
      subdirs = ['src', 'bin', 'dst', 'pkg', 'gen' ]
      pattern = subdirs.collect { |_dir| "/#{Regexp.quote(_dir)}(?=/|$)" }.join('|')

      if Dir.pwd !~ Regexp.new(pattern)
        quoted_subdirs = subdirs.map { |_entry| _entry.inspect }
        raise "Not in product scope (no #{quoted_subdirs.join(', or ')} in current path)"
      end

      @topdir = $PREMATCH
    end

    def ensure_src(&block)
      Dir.cd topsrc, &block
    end

    def obtain_build_from_repository
      max_build = 0
      p4.labels.each do |_label|
        name, build = _label.scan(/(#{@name}.#{@release}).(\d+)/).first
        max_build = build.to_i if build and build.to_i > max_build
      end
      return max_build
    end

    def obtain_name_release_from_repository
      p4.dirs.map { |_line|
        _line.scan(%r{^//([^/]*)/([^/]*)/?}).first
      }.first
    end

    def obtain_product_info
      ensure_src do
        if File.exists? prodinfo
          config = TSC::Config.new prodinfo
          config.load

          @name = config.get :name
          @product = config.get :product
          @release = config.get :release
          @build = config.get :build
          @library_prefix = config.get :library_prefix
          @library_major = config.get :library_major
          @handoff_server = config.get :handoff_server
          @handoff_recepients = config.get :handoff_recepients
        else
          @name, @release = obtain_name_release_from_repository
          @build = obtain_build_from_repository
        end
        unless @name and @release and @build
          raise "Product info not available"
        end
        @library_major ||= @build
        @platform = TSC::Platform.current.name
      end
    end
  end
end

if $0 == __FILE__
  module TSC
    class Product
      def prodinfo
        "kljkljlkjkljlkjlj"
      end
    end
  end
  puts TSC::Product.detect.inspect
end
