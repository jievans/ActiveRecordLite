## Author Josh Evans

require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'
require 'active_support/inflector'

class AssocParams
  attr_accessor :class_name, :primary_key, :foreign_key
  def other_class
    class_name.constantize
  end

  def other_table
    table_name = class_name.tableize
    table_name = table_name == "humen" ? "humans" : table_name
  end
end

class BelongsToAssocParams < AssocParams


  def initialize(name, params)
    default = {:class_name => name.to_s.capitalize,
              :foreign_key => "#{name}_id".to_sym,
              :primary_key => :id}

    params = default.merge(params)

    params.each do |param, value|
      self.send("#{param}=".to_sym, value)
    end
  end

  def type
  end
end

class HasManyAssocParams < AssocParams


  def initialize(name, params, self_class)

      default = {:class_name => name.to_s.singularize.camelize,
              :foreign_key => "#{self.to_s}_id".to_sym,
              :primary_key => :id}


      params = default.merge(params)

      params.each do |param, value|
        self.send("#{param}=".to_sym, value)
      end

  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})

    assoc_params[name] = BelongsToAssocParams.new(name, params)
    belongs = assoc_params[name]

    define_method(name) do

      foreign_key_id = self.send(belongs.foreign_key)

      row_hashes = DBConnection.execute(<<-SQL)
      SELECT #{belongs.other_table}.*
      FROM #{belongs.other_table}
      WHERE #{belongs.other_table}.#{belongs.primary_key} = #{foreign_key_id};
      SQL

      subclass = belongs.class_name.constantize

      subclass.parse_all(row_hashes)

    end

  end

  def has_many(name, params = {})

    assoc_params[name] = HasManyAssocParams.new(name, params, self)
    has = assoc_params[name]

    define_method(name) do

      pkey_id = self.send(has.primary_key)

      row_hashes = DBConnection.execute(<<-SQL)
      SELECT #{has.other_table}.*
      FROM #{has.other_table}
      WHERE #{has.other_table}.#{has.foreign_key} = #{pkey_id};
      SQL

      subclass = has.class_name.constantize

      subclass.parse_all(row_hashes)

    end

  end

  def has_one_through(name, assoc1, assoc2)

    define_method(name) do

      first_assoc = self.class.assoc_params[assoc1]
      second_assoc = first_assoc.other_class.assoc_params[assoc2]

      row_hashes = DBConnection.execute(<<-SQL)
      SELECT #{second_assoc.other_table}.*
      FROM #{second_assoc.other_table} JOIN #{first_assoc.other_table}
      ON #{second_assoc.other_table}.#{second_assoc.primary_key} =
      #{first_assoc.other_table}.#{second_assoc.foreign_key}
      WHERE #{first_assoc.other_table}.#{first_assoc.primary_key} = #{self.id}
      SQL

     second_assoc.other_class.parse_all(row_hashes)

    end

  end
end
