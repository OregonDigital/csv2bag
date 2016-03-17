require 'rdf'

module MappingMethods
  module Replace
    def replace(subject, data)

      if data.include?('http') 
        RDF::Graph.new << RDF::Statement.new(subject, RDF::Vocab::DC.replaces, RDF::URI(data))
      else
        @log.error("Replaces URL should have 'http': " + data)
      end

    end
  end
end
