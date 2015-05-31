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
end

class SQLObject
  extend Associatable
end
