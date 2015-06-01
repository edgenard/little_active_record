require_relative 'db_connection'
require 'active_support/inflector'


class SQLObject
  def self.columns
    column_names = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    
    column_names[0].map(&:to_sym)
    
  end

  def self.finalize!
    self.columns.each{|name| getter_setter(name)}
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.inspect.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL )
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    self.parse_all(results)
    
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = ?
    SQL

    return nil if result.empty? 
    self.new(result[0])
  end

  def initialize(params = {})
    set_params(params)
  end

  def attributes
    @attributes ||= {}
    
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    question_marks = (["?"] * col_names.length).join(", ")
    
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO #{self.class.table_name} (#{col_names.join(", ")})
    VALUES (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_columns = col_names.join("= ?, ") +"= ?"

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_columns}
    WHERE
      id = ?
    SQL
  end

  def save
    self.id ? update : insert
  end
  
  
  private
  
  def col_names
    self.class.columns.map(&:to_s)
  end
  
  def self.getter_setter(name)
    getter = Proc.new { self.attributes[name]}
    setter = Proc.new { |arg| self.attributes[name] = arg}
    
    setter_name = (name.to_s + "=").to_sym

    self.send(:define_method, name, getter)
    self.send(:define_method, setter_name, setter)
  end
  
  def set_params(params)
    self.class.check_keys(params.keys)
    params.each do |key, value|
      setter_name = (key.to_s + "=").to_sym
      self.send(setter_name, value)
    end
  end
  
  
  def self.check_keys(keys)

    check = keys.detect {|key| !self.columns.include?(key.to_sym)}
    raise "unknown attribute '#{check}'" if check
    
  end

  
end
