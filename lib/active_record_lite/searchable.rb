require_relative './db_connection'

module Searchable
  def where(params)

    column_symbols = params.keys
    values = params.values

    where_pieces = column_symbols.map { |col_sym| "#{col_sym} = ?" }
    where_clause = where_pieces.join(" AND ")

    row_hashes = DBConnection.execute(<<-SQL, *values)
    SELECT *
    FROM #{table_name}
    WHERE #{where_clause};
    SQL

    subclass_objects = []

    row_hashes.each do |row_hash|
      subclass_objects << self.new(row_hash)
    end

    subclass_objects
  end
end