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
  attr_reader :name, :params

  def initialize(name, params)
    @name, @params = name, params
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_accessor :class_name, :primary_key, :foreign_key

  def initialize(name, params, self_class)

    # default = {}
    #
    #     ptabel_class_string = params[:foreign_key].to_s[0..-4].camelize
    #
    #     if ptabel_class_string == self_class.to_s
    #       default[:class_name] = name.to_s.singularize.camelize
    #       default[:foreign_key] = self_class.to_s.to_sym
    #     else
    #       default[:class_name] = name.to_s.capitalize
    #       default[:foreign_key] = name.to_s + "_id"
    #     end
    #
    #     default[:primary_key] = :id
    #
    #     params = default.merge(params)

      default = {:class_name => name.to_s.singularize.camelize,
              :foreign_key => "#{name.to_s.singularize}_id".to_sym,
              :primary_key => :id}


      params = default.merge(params)

      # if ftable_name == "humen"
  #       ftable_name = "humans"
  #     end

      params.each do |param, value|
        self.send("#{param}=".to_sym, value)
      end

  end

  def other_table
    unless @class_name.tableize == "humen"
      @class_name.tableize
    else
      "humans"
    end
  end

  def other_class
    @class_name.constantize
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})

    default = {:class_name => name.to_s.capitalize,
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

    assoc_params[name] = BelongsToAssocParams.new(name, params)

    puts assoc_params[name].params

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
    default = {:class_name => name.to_s.singularize.camelize,
              :foreign_key => "#{name.to_s.singularize}_id".to_sym,
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

    define_method(name) do

      step1 = self.class.assoc_params[assoc1]

      step2 = step1.params[:class_name].constantize.assoc_params[assoc2]

      f_table_name = self.class.to_s.tableize
      s_table_name = assoc1.to_s.capitalize.constantize.table_name
      f_fk_label = step1.params[:foreign_key].to_s
      s_pk_label = step1.params[:primary_key].to_s
      t_table_name = assoc2.to_s.pluralize
      s_fk_label = step2.params[:foreign_key].to_s
      t_pk_label = step2.params[:primary_key].to_s


      row_hashes = DBConnection.execute(<<-SQL)
      SELECT #{t_table_name}.*
      FROM #{f_table_name}
      JOIN #{s_table_name}
      ON #{f_table_name}.#{f_fk_label} = #{s_table_name}.#{s_pk_label}
      JOIN #{t_table_name}
      ON #{s_table_name}.#{s_fk_label} = #{t_table_name}.#{t_pk_label}
      WHERE #{f_table_name}.id = #{self.id};
      SQL

     step2.params[:class_name].constantize.parse_all(row_hashes)


    end

  end
end
