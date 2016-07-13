require 'rdf'
require 'rdf/raptor'

module MappingMethods
  module Types
    DCMITYPES = [:Collection, :Dataset, :Event,
                 :Image, :InteractiveReource, :MovingImage,
                 :PhysicalObject, :Service, :Software,
                 :Sound, :StillImage, :Text
                 ]

    def dcmitype_cache
      @dcmitype_cache ||= {}
    end

    def dcmitype(subject, data)
      data = data.capitalize.to_sym
      return nil unless DCMITYPES.include? data
      return RDF::Graph.new << RDF::Statement.new(subject, RDF::Vocab::DC.type, RDF::Vocab::DCMIType[data])
    end

    def types(subject, data)
      graph = RDF::Graph.new
      data = map_types[data] || data
      data.split(';').each do |part|
        part.strip!
        type = dcmitype(subject, part)
        type ||= RDF::Statement.new(subject, RDF::Vocab::DC.type, RDF::Literal.new(part))
        graph << type
      end
      graph
    end

    def image_type(subject, data)
      RDF::Graph.new << RDF::Statement.new(subject, RDF::Vocab::DC.type, RDF::Vocab::DCMIType[:Image])
    end


    def map_types
      {
        'Moving image' => 'MovingImage',
        'image/tiff' => 'Image',
      }
    end
  end
end
