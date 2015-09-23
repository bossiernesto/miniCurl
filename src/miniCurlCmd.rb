require 'optparse'
require_relative '../src/miniCurl'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on('-f', '--configFile FILENAME', 'YAML file with the configuration') {|v|
    dest_opts = YAML.load_file(v)
    options = dest_opts
  }

  opts.on('-d', '--debug FALSE', '') {|v| options['debug'] = v}

  opts.on('-h', '--help', 'Show This message') do
    puts 'MiniCurl\r\n'
    puts 'Usage: ruby miniCurlCmd.rb GET http://test.com/\r\n'
    puts opts
    exit
  end

end.parse!

unless options.has_key? 'method' and options.has_key? 'request' and ARGV.length < 2
  puts 'Invalid way of using miniCurl'
  puts opts
  exit
end

debug = options['debug']
method = ARGV[1] || options['method']
resource = ARGV[2] || options['resource']

curl = MiniCurl.new {}, debug
curl.send method.lower.to_sym, resource


