#!/usr/bin/env ruby
=begin
 
             Tone Software Corporation BSD License ("License")
  
                         Software Build Environment
                         
  Please read this License carefully before downloading this software. By
  downloading or using this software, you are agreeing to be bound by the
  terms of this License. If you do not or cannot agree to the terms of
  this License, please do not download or use the software.
  
  A set of Jam configuration files and a Jam front-end for advanced
  software building with automatic dependency checking for the whole
  project. Provides a hierarchical project description while performing
  build procedures without changing directories. The resulting domain
  language changes emphasis from how to build to what to build. Provides
  separation of compilation artifacts (object files, binaries,
  intermediate files) from the original sources. Comes standard with
  ability to build programs, test suites, static and shared libraries,
  shared modules, code generation, and many others. Provides the bridge to
  ANT for building Java, with abilities to build JNI libraries.
  
  Copyright (c) 2003, 2005, Tone Software Corporation
  
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer. 
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution. 
    * Neither the name of the Tone Software Corporation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission. 
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end 

$:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'tsc/application.rb'
require 'tsc/path.rb'

require 'rubygems'

class Application < TSC::Application
  def start
    handle_errors {
      require 'tsc/jam/config.rb'

      if defined? JAM_ORIGINAL
        invoke JAM_ORIGINAL
      else
        commands = find_in_path(os.exe(script_name))
        commands.shift while commands.first == $0

        raise "No #{script_name.inspect} in PATH" if commands.empty?
        invoke commands.first
      end
    }
  end

  private
  #######

  def expanded_script_location
    @expanded_script_location ||= File.expand_path(script_location)
  end

  def config_location
    @config_location ||= begin
      File.join File.dirname(expanded_script_location), 'config', 'jam'
    end
  end

  def core_config_file
    @core_config_file ||= File.join(config_location, 'Jam.core')
  end

  def cwd
    @cwd ||= Dir.getwd.split(File::SEPARATOR).slice(1..-1)
  end

  def cwd_from_top
    @cwd_from_top ||= begin
      index = cwd.rindex('src')
      raise 'No src in current path' unless index

      cwd.slice(index .. -1)
    end
  end
  
  def project_offset
    figure_project_config.first
  end

  def project_config_file
    figure_project_config.last
  end

  def figure_project_config
    @project_config ||= begin
      config_dir = 'config'
      config_file = 'jam-config.rb'

      top_config_file = File.join(top + [ 'src', config_dir, config_file ])
      return [ '', top_config_file ] if File.file? top_config_file

      path, *extra = Dir[ File.join(top + [ 'src', '*', config_dir, config_file ]) ]
      raise "Multiple project #{config_file.inspect} found" unless extra.empty?

      return [ '', nil ] unless path
      [ path.split(File::SEPARATOR).slice(top.size + 1), path ]
    end
  end

  def top
    Array.new(cwd_from_top.size, '..')
  end

  def invoke(command)
    jam_options = []
    jam_project_options = []

    if File.file? core_config_file
      jam_options = [
        '-f' + core_config_file,
        '-sRUBY=' + (defined?(RUBY_PATH) ? RUBY_PATH : 'ruby'),
        '-sRUBY_PLATFORM=' + RUBY_PLATFORM,
        '-score.PROJECT_OFFSET=' + project_offset,
        '-score.CWD_FROM_TOP=' + cwd_from_top.join(' '),
        '-score.CONFIG=' + config_location, 
        '-score.JAM=' + File.join(expanded_script_location, script_name),
        '-score.CWD=' + Dir.getwd,
        '-score.TOP=' + top.join(' ')
      ]
      if project_config_file
        load project_config_file, false
        arity = JamConfig.allocate.method(:initialize).arity
        config = (arity == 1 ? JamConfig.new(top) : JamConfig.new)
        jam_project_options = config.options
      end
    end

    unless ENV.has_key? 'JAM_NOTQUICK'
      jam_options.push '-q' ;
    end

    cmdline = [ command, jam_options, jam_project_options, ARGV ].flatten.compact

    puts "[#{cmdline.join(' ')}]" if verbose?
    exec *cmdline
  end

  in_generator_context do |_content|
    file = File.basename(target)
    directory = File.join(self.class.installation_top, 'bin')
    original = File.join(directory, 'originals', file)
    ruby = File.join(directory, 'ruby')

    _content << '#!/usr/bin/env ' + figure_ruby_path
    _content << TSC::PATH.current.front(directory).to_ruby_eval
    _content << 'RUBY_PATH = ' + (File.executable?(ruby) ? ruby : figure_ruby_path).inspect
    _content << 'JAM_ORIGINAL = ' +  original.inspect
    _content << IO.readlines(__FILE__).slice(1..-1)
  end
end

Application.new.start
