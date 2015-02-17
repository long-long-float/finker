module Finker
  module Errors
    class Error < StandardError; end

    class FileNotFound < Error; end
    class ConfigFileNotFound < Error
      def message
        "could not find config file(#{Finker::CONFIG_FILE})"
      end
    end

  end
end
