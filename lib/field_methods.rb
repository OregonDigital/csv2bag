class FieldMethods

  def self.field_split(field)
    # Splits multiple field values on delimiters
    # @return [Array] values split or original value as Array

    if field.include?(";")
      result = field.split(/\s*;\s*/)
    elsif field.include?("||")
      result = field.split(/\s*\|\|\s*/)
    else
      # if there is no split, cast to Array, to match behavior of .split
      result = Array(field)
    end
  end
end
