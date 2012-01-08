# vi: set sw=2:
=begin
  Copyright (c) 2008, Quest Software, http://www.quest.com

  This software is property of the mentioned copyright
  holder and cannot be used or distrubuted  other than
  under a written consent agreement between individual
  parties.
=end

require 'tsc/config-locator.rb'
require 'tsc/platform.rb'
require 'tsc/config.rb'
require 'etc'
require 'enumerator'

module TSC
  module Jam
    class Config
      def options
        add_parameter Hash[
          :JAMCONFIG_PRODUCT_TAG => tag,
          :JAMCONFIG_PRODUCT_ID => product,
          :JAMCONFIG_PRODUCT_NAME => name,
          :JAMCONFIG_PRODUCT_RELEASE => release,
          :JAMCONFIG_PRODUCT_BUILD => build,
          :JAMCONFIG_PRODUCT_PLATFORM => platform.name,
          :JAMCONFIG_LIBRARY_PREFIX => library_prefix,
          :JAMCONFIG_LIBRARY_MAJOR => library_major,
          :JAMCONFIG_USER => user
        ]
      end

      protected
      #########

      def add_parameter(*args)
        array = args.flatten.map { |_item|
          Array(_item)
        }
        array.flatten.enum_slice(2).map { |_key, _value|
          value = _value.to_s.strip
          [ '-s', "#{_key}=#{value}" ] unless value.empty?
        }.compact.flatten
      end

      def product
        config['product']
      end

      def tag
        Array([ config['tag'], config['tags'] ]).flatten.compact.join('-')
      end

      def name
        config['name']
      end

      def release
        config['release']
      end

      def build
        config['build']
      end

      def library_prefix
        config['library-prefix']
      end

      def library_major
        config['library-major']
      end

      def user
        Etc.getpwuid.name rescue Etc.getlogin
      end

      def platform
        @platform ||= TSC::Platform.current
      end

      def config
        @config ||= begin
          TSC::Config.parse(File.join(File.dirname(config_path), 'build.yaml')).hash rescue Hash.new
        end
      end

      def buildrc_locator
        @buildrc_locator ||= TSC::ConfigLocator.new('.buildrc')
      end

      def buildrc
        @buildrc ||= begin
          buildrc_locator.find_all_above.inject(Hash[]) { |_memo, _config|
            _config.hash.each_pair do |_key, _value|
              _memo[_key.to_s.downcase] = _value
            end
            _memo
          }
        end
      end

      def environment
        @environment ||= begin
          buildrc['environment'] || buildrc['make'] || Hash[]
        end
      end

      def export_build_resource
        environment.each_pair do |_key, _value|
          ENV[_key] ||= _value.to_s
        end
      end
    end
  end
end

