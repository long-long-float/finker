module Finker
  module Errors
    class Error < StandardError; end

    class FileNotFound < Error
      def initialize(path)
        @path = path
      end

      def message
        "No such file or directory - #{@path}"
      end
    end

    class ConfigFileNotFound < Error
      def message
        "could not find config file(#{Finker::CONFIG_FILE})"
      end
    end

  end
end
