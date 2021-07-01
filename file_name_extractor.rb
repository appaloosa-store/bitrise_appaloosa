#!/usr/bin/env ruby
require 'json'
class FilenameExtractor
  class << self
    SUPPORTED_EXTENSIONS = %w(.ipa .apk .aab)

    def process!
      binary_path = ARGV.first
      raise '[ERROR] $bitrise_ipa_path is empty' if binary_path.empty?
      puts JSON.dump(filename_from_path(binary_path))
    end

    def filename_from_path(path)
      extname = File.extname(path).downcase
      raise "[ERROR] extension is not supported: #{extname}" unless SUPPORTED_EXTENSIONS.include?(extname)
      File.basename(path)
    end
  end
end
FilenameExtractor.process!