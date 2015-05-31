require_relative 'associatable'

module Associatable


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
      source_fk = send(through_name).send(source_fk_name)#humans.house_id
      
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
      
      #through.model_class.find(through.foreign_key).send(source_name)
    end
  end
end
