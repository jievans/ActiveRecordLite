class MyObject
  def self.new_attr_accessor(*args)
    args.each do |method_name|
      define_method(method_name) { self.instance_variable_get("@#{method_name}") }
      define_method("#{method_name}=".to_sym) { |value| self.instance_variable_set("@#{method_name}", value) }
    end
  end

  def self.method_name
    self.instance_variable_get("@#{method_name}")
  end

end

class Cat < MyObject
  new_attr_accessor :x

  def to_s
    "I'm an instance of Cat."
  end
end

x = Cat.new
puts x.x
x.x = 5

x.send(:define_method, :is_instance? { puts self }
x.is_instance?

y = Cat.new
y.is_instance?
# puts x.x
# puts Cat.x
# Cat.x = 5
# puts Cat.x