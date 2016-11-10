#!/usr/bin/env ruby
require 'json'
class FilenameExtractor
	class << self
		def process!
			binary_path = ARGV.first
			raise '[ERROR] $bitrise_ipa_path is empty' if binary_path.empty?
			puts JSON.dump(filename_from_path(binary_path))
		end

		def filename_from_path(path)
			match = path.match(/.+\/(.+\.(ipa|apk))$/)
			raise "[ERROR] could not extract filename from #{path}" unless match
			match[1]
		end
	end
end
FilenameExtractor.process!