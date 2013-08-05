require 'active_record_lite'

# https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
cats_db_file_name =
  File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
DBConnection.open(cats_db_file_name)

class Cat < SQLObject
  set_table_name("cats")
  set_attrs(:id, :name, :owner_id)

  belongs_to :human, :class_name => "Human", :primary_key => :id, :foreign_key => :owner_id
  has_one_through :house, :human, :house
end

class Human < SQLObject
  set_table_name("humans")
  set_attrs(:id, :fname, :lname, :house_id)

  has_many :cats, :foreign_key => :owner_id
  belongs_to :house
end

class House < SQLObject
  set_table_name("houses")
  set_attrs(:id, :address, :house_id)
end

cat = Cat.find(1)
puts "The Cat"
p cat
puts
puts "The Cat's Human"
p cat.human
puts
puts "The Human"
human = Human.find(1)
puts human
puts
puts "Human's cats"
p human.cats
puts

puts "Human's house"
p human.house
puts

puts "Cat's house"
p cat.house
