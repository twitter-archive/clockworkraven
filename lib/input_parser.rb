# Copyright 2012 Twitter, Inc. and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'set'

class String
  # Taken from http://stackoverflow.com/a/4585362/231588
  def to_my_utf8
    if RUBY_VERSION < "1.9"
      require 'iconv'
      ::Iconv.conv('UTF-8//IGNORE', 'UTF-8', self + ' ')[0..-2]
    else
      self.force_encoding 'UTF-8'
    end
  end
end

module InputParser
  class << self
    # Given an uploaded file, returns the parsed version suitable for
    # Evaluation#add_tasks
    #
    # Throws InputParser::ParseError if the file is malformed
    def parse(file)
      type = File.extname(file.original_filename)
      content = file.read.to_my_utf8

      begin
        case type
        when '.json'
          return parse_json(content)
        when '.csv'
          return parse_csv(content, ',')
        when '.tsv'
          return parse_csv(content, "\t")
        else
          raise ParseError.new("Unsupported file extension")
        end
      rescue CSV::MalformedCSVError => e
        raise ParseError.new("Malformed CSV", e)
      rescue MultiJson::DecodeError => e
        raise ParseError.new("Malformed JSON", e)
      end
    end

    private

    # Just parse the json
    def parse_json content
      json = ActiveSupport::JSON.decode(content)

      # validation
      validate json.kind_of?(Array), "JSON was not an array"

      json.each do |item|
        validate item.kind_of?(Hash), "JSON was not an array of objects"
        validate (item.keys.to_set == json.first.keys.to_set),
                 "JSON objects did not have consistent keys"
      end
    end

    # Convert the CSV to the equivalent JSON
    def parse_csv content, sep
      CSV.parse(content, :col_sep => sep,
                         :converters => [:numeric],
                         :headers => true,
                         :skip_blanks => true,
                         :quote_char => "\x00").
          map{ |row| row.to_hash }
    end

    # Raises a ParseError if bool is false, using the given message
    def validate bool, message
      unless bool
        raise ParseError.new message
      end
    end
  end

  class ParseError < RuntimeError
    attr_reader :msg, :source

    def initialize msg, source=nil
      @msg = msg
      @source = source
    end
  end
end