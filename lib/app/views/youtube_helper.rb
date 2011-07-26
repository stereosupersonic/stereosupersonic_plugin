module StereosupersonicPlugin
  module YoutubeHelper

    def video_html(video)
      unless video.blank?
        raw %Q(    
        <div class="video ">
        <embed src="http://www.youtube.com/v/#{video}&hl=en&fs=1} 
        type="application/x-shockwave-flash" 
        width="425" height="355" autoplay="TRUE" scale="ASPECT" allowfullscreen="TRUE">
        </embed>  
        </div>      
        )
      end    
    end      

    def youtube_html5(youtube_id)
      unless youtube_id.blank?
        frameborder = 0
        width = 390
        height = 250
        raw  %Q(    
        <div class="video">
        <iframe class="youtube-player" 
        type="text/html" width="#{width}" 
        height="#{height}" 
        src="http://www.youtube.com/embed/#{youtube_id}" 
        frameborder="#{frameborder}">
        </iframe>     
        </div>      
        )
      end
    end


    def fetch(format, artist_or_song)
      require 'open-uri'        
      begin
        Timeout::timeout(3) do
          encoded_artist_or_song = URI.encode(artist_or_song)
          url = format % [encoded_artist_or_song]
          #puts url
          data = open(url).read
        end
      rescue Exception => problem
        nil
      end
    end

    def youtube_xml(artist_or_song)
      youtube_format = "http://gdata.youtube.com/feeds/api/videos?q=%s&v=2&restriction=DE&category=Music&max-results=1"
      fetch(youtube_format, artist_or_song)    
    end

    def parse_xml(xml)
      #puts "parse with nokogiri"
      require 'nokogiri'  
      doc = Nokogiri::XML xml
      url = (doc.xpath('//media:content').map {|e| e.attr('url')} rescue []).first.to_s
      url[/\/v\/([\S]*)\?/,1]
    end

    def fetch_youtube_id(options)      
      artist_or_song = "#{options[:artist].gsub(/\b\w/){$&.downcase}}-#{options[:song].gsub(/\b\w/){$&.downcase}}"
      xml = youtube_xml(artist_or_song)
      videoid = xml.to_s[/<yt:videoid>([\S]*)<\/yt:videoid>/,1]  
      videoid.blank? ? parse_xml(xml) : videoid
    end
  end

end

ActionView::Base.send :include, StereosupersonicPlugin::YoutubeHelper