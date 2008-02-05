=begin
  Copyright (c) 2008, Quest Software, http://www.quest.com
  
  This software is property of the mentioned copyright
  holder and cannot be used or distrubuted  other than 
  under a written consent agreement between individual 
  parties.
=end

require 'tsc/config-locator.rb'

module TSC
  module Jam
    class Config
      def locator 
        @locator ||= TSC::ConfigLocator.new('.buildrc')
      end

      def config
        @config ||= begin
          locator.find_all_above.inject(Hash[]) { |_memo, _config|
            _memo.update _config.hash
          }
        end
      end

      def environment
        @environment ||= begin
          config['environment'] || Hash[]
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

