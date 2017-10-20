require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map {|key| "#{key} = ?"}.join(" AND ")
    param_vals = params.values
    #haskell_cats = Cat.where(:name => "Haskell", :color => "calico")
    # SELECT
    #   *
    # FROM
    #   cats
    # WHERE
    #   name = ? AND color = ?
    result = DBConnection.execute(<<-SQL, *param_vals)

    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}

    SQL
    p parse_all(result)
  end
end

class SQLObject
  extend Searchable
end
