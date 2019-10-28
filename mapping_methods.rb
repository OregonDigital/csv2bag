
Dir["./mapping_methods/*.rb"].each { |f| require f }

module MappingMethods
  include MappingMethods::Geographic
  include MappingMethods::Rights
  include MappingMethods::License
  include MappingMethods::MediaType
  include MappingMethods::XSDDate
  include MappingMethods::Language
  include MappingMethods::Types
  include MappingMethods::Premis
  include MappingMethods::AAT
  include MappingMethods::Collection
  include MappingMethods::Replace
  include MappingMethods::Ethnographic
  include MappingMethods::Subject
  include MappingMethods::Institution
  include MappingMethods::Sports
  include MappingMethods::Cleanup
  include MappingMethods::Creator
  include MappingMethods::Set
end
