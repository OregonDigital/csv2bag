module MappingMethods
  module Institution
    def institution(subject, data)
      return if !data || data == ""
      return unless mapping.include?(data)
      RDF::Graph.new << RDF::Statement(subject, RDF::URI("http://opaquenamespace.org/ns/contributingInstitution"), RDF::URI(mapping[data]))
    end

    def mapping
      {
        "Oregon State University Libraries" => "http://id.loc.gov/authorities/names/n80017721"
      }
    end
  end
end
