module StereosupersonicPlugin
  module ActionView
    
    def incluce_google_webmastertools(options={})
      if options[:key]
        %{
          <meta name="google-site-verification" content="#{options[:key]}" />
         }
       end
    end  
    
    def include_google_analytics(options={})
       if options[:key]
         <<-EOF
           <script type="text/javascript"> 

             var _gaq = _gaq || [];
             _gaq.push(['_setAccount', '#{options[:key]}']);
             _gaq.push(['_trackPageview']);

             (function() {
               var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
               ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
               var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
             })();
           </script>
    
         EOF
       end
     end
     
    
  end
end

ActionView::Base.send :include, StereosupersonicPlugin::ActionView

