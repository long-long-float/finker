module Finker
  module Errors
    class Error < StandardError; end

    class FileNotFound < Error; end
    class ConfigFileNotFound < Error; end

  end
end
