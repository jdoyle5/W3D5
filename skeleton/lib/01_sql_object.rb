require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.



class SQLObject

  def self.columns
    return @columns if @columns
    everything = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        '#{table_name}'
    SQL
    @columns = everything.first.map {|el| el.to_sym}
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end

      define_method(column) do
        self.attributes[column]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.downcase.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)

      SELECT *
      FROM #{table_name}

    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map {|el| self.new(el)}
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)

      SELECT #{table_name}.*
      FROM #{table_name}
      Where #{table_name}.id = ?

    SQL
    parse_all(result).first
  end

  def initialize(params = {})
    params.each do |name, val|
      att_name = name.to_sym
      if self.class.columns.include?(att_name)
        self.send("#{name}=", val)
      else
        raise "unknown attribute '#{name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |instance|
      send(instance)
    end
  end

  def col_names
    (self.class.columns.map { |el| el.to_s}).join(", ")
  end

  def question_marks
    arr_marks = []
    self.class.columns.length.times do
      arr_marks << '?'
    end
    arr_marks.join(", ")
  end

  def insert
    DBConnection.execute(<<-SQL, *attribute_values)

    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})

    SQL
    self.id = DBConnection.last_insert_row_id
  end

  # def update
  #    set_line = self.class.columns
  #      .map { |attr| "#{attr} = ?" }.join(", ")
  #
  #    DBConnection.execute(<<-SQL, *attribute_values, id)
  #      UPDATE
  #        #{self.class.table_name}
  #      SET
  #        #{set_line}
  #      WHERE
  #        #{self.class.table_name}.id = ?
  #    SQL
  #  end

  def update
    set_line = self.class.columns.map do |attr_name|
      "#{attr_name} = ?"
    end
    set = set_line.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)

    UPDATE
      #{self.class.table_name}
    SET
      #{set}
    WHERE
      #{self.class.table_name}.id = ?

    SQL
  end

  def save
    id.nil? ? self.insert : self.update
  end
end
