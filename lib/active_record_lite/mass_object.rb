class MassObject
  def self.set_attrs(*attributes)
    attributes.each do |attribute|
      attr_accessor attribute
      self.attributes << attribute
    end
  end

  def self.attributes
    @attributes ||= []
  end

  def self.parse_all(results)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.attributes.include?(attr_name.to_sym)
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
      self.send("#{attr_name}=", value)
    end
  end
end
