require 'net/http'

class CacertExtractor

  CACERT_URL = 'http://curl.haxx.se/ca/cacert.pem'

  def get_cacert
    directory_name = File.dirname(__FILE__) + '/certs'

    Dir.mkdir(directory_name) unless File.exists?(directory_name)

    File.open(File.dirname(__FILE__) + '/certs/cacert.pem', 'w')  do |f|
      Net::HTTP.start('curl.haxx.se') do |http|
        http.get(CACERT_URL) do |pemfile|
          f.write pemfile
        end
      end
    end
  end

end