require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'
require 'active_support/inflector'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params

  end

  def belongs_to(name, params = {})

    default = {:class_name => self.to_s,
              :foreign_key => "#{name}_id".to_sym,
              :primary_key => :id}

    params = default.merge(params)

    ptable_name = params[:class_name].tableize
    ftable_name = self.to_s.tableize
    fkey_label = params[:foreign_key].to_s
    pkey_label = params[:primary_key].to_s

    # p params[:class_name].tableize

    if ptable_name == "humen"
      ptable_name = "humans"
    end

    # p ptable_name
#     p ftable_name
#     p fkey_label
#     p pkey_label


    define_method(name) do

      foreign_key_id = self.send(params[:foreign_key])

      row_hashes = DBConnection.execute(<<-SQL)
      SELECT #{ptable_name}.*
      FROM #{ptable_name}
      WHERE #{ptable_name}.#{pkey_label} = #{foreign_key_id};
      SQL

      subclass = params[:class_name].constantize

      subclass.parse_all(row_hashes)

    end

  end

  def has_many(name, params = {})
    default = {:class_name => name.to_s.singularize.capitalize,
              :foreign_key => "#{name}_id".to_sym,
              :primary_key => :id}

    params = default.merge(params)

    ptable_name = self.to_s.tableize
    ftable_name = params[:class_name].tableize
    fkey_label = params[:foreign_key].to_s
    pkey_label = params[:primary_key].to_s



    if ftable_name == "humen"
      ftable_name = "humans"
    end



    define_method(name) do

      pkey_id = self.send(params[:primary_key])

      row_hashes = DBConnection.execute(<<-SQL)
      SELECT #{ftable_name}.*
      FROM #{ftable_name}
      WHERE #{ftable_name}.#{fkey_label} = #{pkey_id};
      SQL

      subclass = params[:class_name].constantize

      subclass.parse_all(row_hashes)

    end


  end

  def has_one_through(name, assoc1, assoc2)
  end
end
