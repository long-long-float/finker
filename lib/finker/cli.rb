require "finker"
require "thor"

require 'yaml'
require 'fileutils'
require 'pathname'

module Finker
  class CLI < Thor
    include Thor::Actions

    def initialize(args = [], options = {}, config = {})
      super

      unless File.exist?(Finker::CONFIG_FILE)
        raise Finker::Errors::ConfigFileNotFound
      end

      @config = Finker::Config.new
    end

    desc 'setup', 'move from original files and create symbolic links'
    def setup
      @config.each_links do |path, raw_path|
        dirpath = File.dirname(raw_path)
        File.exist?(raw_path) || FileUtils.mkdir_p(dirpath)

        unless File.exist?(path)
          raise Finker::Errors::FileNotFound, path
        end

        if File.lstat(path).ftype == 'link'
          # skip if it has already set up
          next
        end

        FileUtils.mv(path, raw_path)
        FileUtils.ln_s(raw_path, path)
      end
    end

    desc 'install', 'remove original files and create symbolic links'
    def install
      @config.each_links do |path, raw_path|
        if File.exist?(path)
          if yes?("Would you remove #{path}?")
            FileUtils.rm(path)
          else
            next
          end
        end

        unless File.exist?(raw_path)
          raise Finker::Errors::FileNotFound, raw_path
        end

        FileUtils.ln_s(raw_path, path)
      end
    end

    desc 'uninstall', 'remove linked files and copy here files'
    def uninstall
      @config.each_links do |path, raw_path|
        File.exist?(path) && FileUtils.rm(path)
        FileUtils.cp(raw_path, path)
      end
    end

    desc 'status', 'show status of files under management'
    def status
      @config.each_links do |path|
        print "#{path} - "

        status = File.exist?(path) ? nil : 'not existing'
        unless status
          status = {'link' => 'linked', 'file' => 'unlinked'}[File.ftype(path)]
        end
        puts status
      end
    end
  end
end
