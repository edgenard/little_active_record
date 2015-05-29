require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    self.check_keys(params.keys)
    columns = params.keys.map(&:to_s).join("= ? AND ") + "= ?"
    search_criteria = params.values
    search_result = DBConnection.execute(<<-SQL, *search_criteria)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{columns}
    SQL
    
    return [] if search_result.empty?
    search_result.map {|result| self.new(result)}
  end


end

class SQLObject
  extend Searchable
end
