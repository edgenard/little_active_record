require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.camelize.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || (name.to_s + "_id").to_sym
    @class_name = options[:class_name] || name.to_s.capitalize
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] ||
                  (self_class_name.downcase + "_id").to_sym
    @class_name = options[:class_name] || name.to_s.singularize.capitalize
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    foreign_key_name = self.assoc_options[name].foreign_key
    
    define_method(name) do 
      owner_id = send(foreign_key_name) 
      owner_class = self.class.assoc_options[name].model_class
      owner_class.find(owner_id)
    end
  end

  def has_many(name, options = {})
    self_class_name = self.name
    assoc_options[name] = HasManyOptions.new(name, self_class_name, options)
    ownee_class = self.assoc_options[name]
    define_method(name) do
      foreign_key_name = self.class.assoc_options[name].foreign_key
      ownee_class.model_class.where(foreign_key_name => self.id)
    end 
  end
  

  def assoc_options
    @assoc_options ||= {}
  end
  
  def has_one_through(name, through_name, source_name)
    
  
    define_method(name) do
      through_options = self.class.assoc_options[through_name]#human
      #house
      source_options = through_options.model_class.assoc_options[source_name] 
      
      source_table = source_options.model_class.table_name #houses
      through_table = through_options.model_class.table_name #humans
      
      through_fk_name = through_options.foreign_key #owner_id
      through_fk = send(through_fk_name) #cats.owner_id
      
      source_fk_name = source_options.foreign_key#house_id

      
      through_pk = through_options.primary_key.to_s
      source_pk = source_options.primary_key.to_s #id

      result = DBConnection.execute(<<-SQL, through_fk.to_s)
      SELECT
        #{source_table}.*
      FROM
        #{through_table}
      JOIN
        #{source_table} ON #{through_table}.#{source_fk_name} = #{source_table}.#{source_pk.to_s}
      WHERE
        #{through_table}.#{through_pk.to_s} = ?
        
      SQL

      source_options.model_class.parse_all(result).first
      
    end
  end
  
  
end

class SQLObject
  extend Associatable
end
