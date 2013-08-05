require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject

  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name.tableize
  end

  def self.table_name
    @table_name
  end

  def self.all
    sql_objects = []

    row_hashes = DBConnection.execute(<<-SQL)
    SELECT * FROM #{@table_name};
    SQL

    row_hashes.each do |row_hash|
      sql_objects << self.new(row_hash)
    end

    sql_objects
  end

  def self.find(id)
    row_hash = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{@table_name}
    WHERE #{@table_name}.id = #{id};
    SQL
    self.new(row_hash.first)
  end

  def save
    unless self.id.nil?
      update
    else
      create
    end
  end

  def attribute_values
    self.instance_variables.map do |var_sym|
      instance_variable_get(var_sym)
    end
  end

  private

  def create
    instance_strings = self.instance_variables.map do |var_symbol|
      var_symbol.to_s[1..-1]
    end

    column_list = instance_strings.join(", ")

    instance_values = attribute_values

    values_holder = Array.new(self.instance_variables.length) { "?" }.join(", ")

    table_name = self.class.table_name

    DBConnection.execute(<<-SQL, *instance_values)
    INSERT INTO #{table_name} (#{column_list})
    VALUES (#{values_holder});
    SQL

    id_hash_array = DBConnection.execute(<<-SQL)
    SELECT #{table_name}.id FROM #{table_name} ORDER BY #{table_name}.id DESC LIMIT 1;
    SQL

    #must be a way to refactor this
    self.id = id_hash_array.first["id"]

  end

  def update

    instance_strings = self.instance_variables.map do |var_symbol|
      var_symbol.to_s[1..-1] + " = ?"
    end

    column_list = instance_strings.join(", ")

    instance_values = attribute_values

    table_name = self.class.table_name

    DBConnection.execute(<<-SQL, *instance_values)
    UPDATE #{table_name}
    SET #{column_list}
    WHERE id = #{self.id};
    SQL

  end
end


