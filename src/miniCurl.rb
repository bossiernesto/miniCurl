require 'socket'
require 'uri'
require 'openssl'
require 'ostruct'

class MiniCurl

  attr_accessor :socket, :uri, :raw_uri, :valid_methods, :version, :debug

  def initialize(options={}, debug = false)
    self.valid_methods = [:get, :delete]
    self.version = options['version'] || 1.1
    self.debug = debug
  end

  def detele(uri_input)
    self.get_generic_resource uri_input, :delete
  end

  def get(uri_input)
    self.get_generic_resource uri_input, :get
  end

  def get_generic_resource(uri_input, method)
    self.raw_uri = uri_input
    self.parse_uri
    socket_response = self.get_resource method
    self.show_response socket_response
  end

  def parse_uri
    complete_uri = (self.raw_uri.start_with? "http://" or self.raw_uri.start_with? "https://") ? self.raw_uri : "http://#{self.raw_uri}/"
    self.uri = URI.parse complete_uri
  end

  def get_resource(method)
    socket = self.send "get_#{self.uri.scheme}_socket".to_sym
    self.check_method method
    socket.puts "#{method.to_s.upcase} / HTTP/#{self.version.to_s}"
    socket.puts "Host: #{self.uri.host}"
    socket.puts 'Connection: close' # Tell server to close
    # connection when done.
    socket.puts "\n"                # Empty line to indicate
    # end of request.
    socket
  end

  def show_response(socket_response)
    content = ''
    headers = self.parse_http_request socket_response
    while line = socket_response.gets
      content += line # Print the response data until we run out of text.
    end

    if debug
      puts content
    end
    puts "Done downloading #{self.raw_uri}. Downloaded #{content.length} bytes"
    socket_response.close

    struct = OpenStruct.new
    struct.headers = headers
    struct.code = headers['Heading'].split(' ')[1]
    struct.length = content.length
    struct.content = content
    struct
  end

  # Takes a HTTP request and parses it into a map that's keyed
  # by the title of the heading and the heading itself.
  # Request should always be a TCPSocket object.
  def parse_http_request(request)
    headers = {}

    #get the first heading (first line)
    headers['Heading'] = request.gets.gsub /^"|"$/, ''.chomp
    method = headers['Heading'].split(' ')[0]

    #parse the header
    while true
      #do inspect to get the escape characters as literals
      #also remove quotes
      line = request.gets.inspect.gsub /^"|"$/, ''

      #if the line only contains a newline, then the body is about to start
      break if line.eql? '\r\n'

      label = line[0..line.index(':')-1]

      #get rid of the escape characters
      val = line[line.index(':')+1..line.length].tap{|val|val.slice!('\r\n')}.strip
      headers[label] = val
    end

    #If it's a POST, then we need to get the body
    if method.eql?('POST')
      headers['Body'] = request.read(headers['Content-Length'].to_i)
    end

    headers
  end

  def check_method(method)
    unless self.valid_methods.include? method
      raise MiniCurlException, "Invalid method #{method}"
    end
  end

  def get_https_socket
    socket = self.get_socket
    ssl_context = self.get_ssl_context
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl_socket.sync_close = true
    ssl_socket.connect
    ssl_socket
  end

  def get_http_socket
    self.get_socket
  end

  def get_socket
    TCPSocket.new self.uri.host, uri.port
  end

  def get_ssl_context
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = OpenSSL::X509::Certificate.new(self.get_pem)
    ssl_context.ssl_version = :SSLv23
    ssl_context
  end

  def get_pem
    path = File.dirname(__FILE__) + '/certs/cacert.pem'
    begin
      File.open(path)
    rescue Errno::ENOENT
      require_relative 'cacertExtractor'

      CacertExtractor.new.get_cacert
      File.open(path)
    end
  end

end

class MiniCurlException < StandardError
end