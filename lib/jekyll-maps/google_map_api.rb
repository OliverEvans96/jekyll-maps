module Jekyll
  module Maps
    class GoogleMapApi
      HEAD_END_TAG = %r!</[\s\t]*head>!

      class << self
        def prepend_api_code(doc)
          @config = doc.site.config
          if doc.output =~ HEAD_END_TAG
            # Insert API code before header's end if this document has one.
            doc.output.gsub!(HEAD_END_TAG, %(#{api_code}#{Regexp.last_match}))
          else
            doc.output.prepend(api_code)
          end
        end

        private
        def api_code
          <<HTML
<script type='text/javascript'>
  #{js_lib_contents}
</script>
#{load_google_maps_api}
#{load_marker_with_label}
#{load_marker_cluster}
HTML
        end

        private
        def load_google_maps_api
          api_key = @config.fetch("maps", {})
            .fetch("google", {})
            .fetch("api_key", "")
          map_options = @config.fetch("maps", {})
                      .fetch("google", {})
                      .fetch("map_options", {})
          <<HTML
<script src='https://maps.googleapis.com/maps/api/js?key=#{api_key}&callback=#{Jekyll::Maps::GoogleMapTag::JS_LIB_NAME}.initializeMap(#{JSON.generate(map_options)})'></script>
HTML
        end

        private
        def load_marker_with_label
          <<HTML
<script src='http://cdn.sobekrepository.org/includes/gmaps-markerwithlabel/1.9.1/gmaps-markerwithlabel-1.9.1.js'</script>
HTML
        end

        private
        def load_marker_cluster
          settings = @config.fetch("maps", {})
            .fetch("google", {})
            .fetch("marker_cluster", {})
          return unless settings.fetch("enabled", true)
          <<HTML
<script src='https://cdn.rawgit.com/googlemaps/js-marker-clusterer/gh-pages/src/markerclusterer.js'
        Jekyll::Maps::GoogleMapTag::JS_LIB_NAME}.initializeCluster(#{settings.to_json})'></script>
HTML
        end

        private
        def js_lib_contents
          @js_lib_contents ||= begin
            File.read(js_lib_path)
          end
        end

        private
        def js_lib_path
          @js_lib_path ||= begin
            File.expand_path("./google_map_api.js", File.dirname(__FILE__))
          end
        end
      end
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  if doc.output =~ %r!#{Jekyll::Maps::GoogleMapTag::JS_LIB_NAME}!
    Jekyll::Maps::GoogleMapApi.prepend_api_code(doc)
  end
end
