require 'rdf'

module MappingMethods
  module Set
    # Main Set method. Can accept other predicates (for Primary Set)
    # Valid incoming data is either only Set ID 'osu-scarc' or full URI: http://oregondigital.org/resource/oregondigital:osu-scarc
    def set (subject, data, predicate=@namespaces["oregon"]["set"])
      graph = RDF::Graph.new
      set_uri_base = "http://oregondigital.org/resource/oregondigital:"
      set_uri = ""

      if data.include?(' ')
        @log.error("Space found in Set URI or ID: " + data)
      elsif data.include?('http:')
        # Check full URI
        if data.include?(set_uri_base)
          set_uri = data
        else
          @log.error("Set URI missing correct base: " + data)
        end
      else
        # Add the URI prefix to the Set ID
        set_uri = set_uri_base + data
      end

      if !set_uri.to_s.empty?
        graph << RDF::Statement(subject, predicate, RDF::URI(set_uri))
      end

      @log.info("Set URI = " + set_uri)

      graph
    end

    def primarySet(subject, data)
      set(subject, data, @namespaces["oregon"]["primarySet"])
    end
  end
end
