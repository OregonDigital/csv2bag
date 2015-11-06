require 'rdf'
require 'json/ld'
require 'sparql'
require 'sparql/client'
require 'rdf/vocab/rdfs'

module MappingMethods
  module Collection

    def collection_from_opaquens(subject, data)
      @collections ||= RDF::Graph.load("https://raw.githubusercontent.com/OregonDigital/opaque_ns/master/localCollectionName.jsonld")
      return if data.nil? || data.strip == ""
      @collection_client ||= SPARQL::Client.new(@collections)
      data = data.split(";").map{|x| x.strip}
      graph = RDF::Graph.new
      @collection_query_cache ||= {}
      data.each do |collection|
        query = @collection_query_cache[collection.downcase] || @collection_client.query("SELECT DISTINCT ?s ?p ?o WHERE { ?s <#{RDF::RDFS.label}> ?o. FILTER(strstarts(lcase(?o), '#{collection.downcase}'))}")
        @collection_query_cache[collection.downcase] ||= query
        solution = query.first
        if solution
          graph << RDF::Statement.new(subject, RDF::URI("http://opaquenamespace.org/ns/localCollectionName"), solution[:s])
        else
          puts "No collection match found for #{collection}"
          graph << RDF::Statement.new(subject, RDF::URI("http://opaquenamespace.org/ns/localCollectionName"), collection)
        end
      end
      graph
    end

    def collection(subject, data)
      data = data.gsub(';','')
      collection = data
      puts "No URI found for #{data}" unless collection.kind_of? RDF::URI
      graph = RDF::Graph.new << RDF::Statement.new(subject, RDF::Vocab::DC.isPartOf, collection)
      graph
    end
  end
end
