require_relative '../../util/not_supported_exception'

class MapForumlaeToLinkedHTML

  def map(ast)
    return ast unless ast.is_a?(Array) # i.e., a value such as 1
    if ast.first.is_a?(Symbol) # i.e., [:operator, '+']
      operator = ast[0]
      arguments = ast[1..-1]
      if respond_to?(operator)
        send(operator,*arguments)
      else
        default(operator, arguments)
      end
    else # i.e., a stream of arguments [[:number, '1'], [:operator, '+'], [:number, '2']]
      ast.map do |a|
        map(a)
      end
    end
  end

  def default(operator, arguments)
    "[#{operator}, #{map(arguments).join(", ")}]"
  end

  def function(name, *arguments)
    "#{name.upcase}(#{map(arguments).join(', ')})"
  end

  def brackets(*arguments)
    "(#{map(arguments).join('')})"
  end

  def string_join(*arguments)
    map(arguments).join('&')
  end

  def arithmetic(*arguments)
    map(arguments).join('')
  end

  def comparison(*arguments)
    map(arguments).join('')
  end

  def string(s)
    s.inspect
  end

  def percentage(p)
    "#{p*100}%"
  end

  def number(n)
    n
  end

  def operator(op)
    op
  end

  # Must implement:
  # external_reference
  # table_reference
  # local_table_rereference
  # named_reference
  # column_range
  # row_range

  def sheet_reference(sheet,reference)
    @sheet = sheet+".html"
    s = map(reference)
    @sheet = nil
    s
  end
  
  def area(start,finish)
    "<a href=\"#{@sheet}##{start.gsub('$','')}:#{finish.gsub('$','')}\">#{start}:#{finish}</a>"
  end

  def cell(ref)
    "<a href=\"#{@sheet}##{ref.gsub('$','')}\">#{ref}</a>"
  end

  def boolean_false()
    'FALSE'
  end

  def boolean_true()
    'TRUE'
  end

  def prefix(op, *arguments)
    op + map(arguments).join('')
  end

  def null()
    ', '
  end

end


class CompileToHTML
  
  attr_accessor :dimensions
  attr_accessor :formulae
  attr_accessor :values
  attr_accessor :title

  def self.rewrite(*args)
    self.new.rewrite(*args)
  end
  
  def rewrite(sheet_name,o)
    # d = dimensions[sheet_name]
    d = check_dimensions(sheet_name) # if d.length > 5 # Sometimes excel goes mad and has insane sheet dimensions
    cells = Area.for(d).to_array_literal

    # Put in the header and preamble
    o.puts <<-END
    <html>
      <link href='application.css' rel='stylesheet' type='text/css' />
      <script type='text/javascript' src='jquery.min.js'></script>
      <script type='text/javascript' src='application.js'></script>
      <body>

      <div id='top'>
          <h1>#{title}</h1>
          <table>
            <tr>
              <td id='sheetref'>'#{sheet_name}'!<span id='selectedcell'></span></td>
              <td id='functionof'>&fnof;<i>x</i></td>
              <td id='selectedformula'>&nbsp;</td>
            </tr>
          </table>
      </div>

      <div id='worksheet'>
    END

    # Put in the worksheet
    o.puts "<table class='cells'>"
    cells.shift # :array

    # Put in the header row
    o.puts "<tr>"
    cells.first.each do |cell|
      if cell.is_a?(Array)
        o.puts "<th>#{cell.last[/[a-zA-Z]+/]}</th>"
      else
        o.puts "<th></th>"
      end
    end
    o.puts "</tr>"

    # Put in the actual content
    cells.each do |row|
      o.puts "<tr>"
      # Put in the row number
      o.puts "<th>#{row[1].last[/[0-9]+/]}</th>"
      row.shift # :row
      row.each do |cell|
        ref = cell.last
        o.puts "<td id='c#{ref}' class='c#{ref}' data-formula='#{formula(sheet_name,ref)}'>#{formatted_value(sheet_name, ref)}</td>"
      end
    end
    o.puts "</table>"
    o.puts "<p>Generated on #{Time.now} by <a href='http://github.com/tamc/excel_to_code'>excel_to_code</a></p>"
    o.puts "</div>"

    o.puts "<div id='jumpbar'><table><tr>"
    dimensions.each do |name, dimensions|
      o.puts "<td class='#{name == sheet_name && "current"}'><a href='#{name}.html' >#{name}</a></td>"
    end
    o.puts "</table></div>"

    # Put in the closing tags
    o.puts "</body>"
    o.puts "</html>"
  end
  
  def formatted_value(sheet, cell)
    v = values[sheet][cell]
    return nil unless v
    case v.first
    when :number
      v.last.to_f.round
    else
      v.last
    end
  end

  def value(sheet, cell)
    v = values[sheet][cell]
    return nil unless v
    v.last
  end

  def formula(sheet, cell)
    f = formulae[sheet][cell]
    return "&nbsp;" unless f
    ast_to_html(f)
  end

  def ast_to_html(ast)
    @mapper ||= MapForumlaeToLinkedHTML.new
    @mapper.map(ast)
  end

  def check_dimensions(sheet_name)
    max_row = maximum_row_in(values[sheet_name])
    max_col = maximum_column_in(values[sheet_name])
    "A1:#{max_col.excel_column}#{max_row.excel_row}"
  end

  def maximum_row_in(hash)
    hash.keys.map do |c| 
      Reference.for(c)
    end.sort_by do |r|
      r.calculate_excel_variables
      r.excel_row_number
    end.last
  end
      
  def maximum_column_in(hash)
    r = hash.keys.map do |c| 
      Reference.for(c)
    end.sort_by do |r|
      r.calculate_excel_variables
      r.excel_column_number
    end.last
  end

  def worksheet_dimensions=(worksheet_dimensions)
    @dimensions =  Hash[worksheet_dimensions.readlines.map do |line| 
      worksheet_name, area = line.split("\t")
      [worksheet_name,area]
    end]
    @mapper = nil
  end
end
