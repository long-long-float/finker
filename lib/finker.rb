require "finker/version"
require "finker/cli"

module Finker
  CONFIG_FILE = 'Finkerfile'

  class Config
    def initialize
      @config = YAML.load_file(CONFIG_FILE)
    end

    def expand_env_var(path)
      path.gsub(/\$(\w+)/){|n| ENV[$1] }
    end

    def expand_links(parents, child)
      case child
      when String
        [File.join(*parents, child)]
      when Array
        child.map do |path|
          self.expand_links(parents, path)
        end
      when Hash
        ret = []
        child.each do |key, val|
          new_parent = parents.dup << key
          ret.concat self.expand_links(new_parent, val)
        end
        ret
      end
    end

    def each_links
      link = @config['link']
      self.expand_links([], link).flatten.each do |path|
        yield expand_env_var(path), path
      end
    end
  end
end
