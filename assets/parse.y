class HCLParser
token BOOL
      FLOAT
      NUMBER
      COMMA
      COMMAEND
      IDENTIFIER
      EQUAL
      STRING
      MINUS
      LEFTBRACE
      RIGHTBRACE
      LEFTBRACKET
      RIGHTBRACKET
      PERIOD
      EPLUS
      EMINUS

rule
  target: top { @result = flatten_objectlist(val[0])}

  top:
      { result = val[0] }
  |  objectlist
  ;


  objectlist:
     objectitem
       { result = [val[0]] }
  |  objectlist objectitem
       { result = val[0] << val[1]  }
  ;

  object:
     LEFTBRACE objectlist RIGHTBRACE
       { result = flatten_objectlist(val[1]) }
  |  LEFTBRACE RIGHTBRACE
       { return }
  ;

  objectkey:
     IDENTIFIER
       { result = val[0] }
  |  STRING
       { result = val[0] }
  ;

  objectitem:
     objectkey EQUAL number
       { result = val[0], val[2] }
  |  objectkey EQUAL BOOL
       { result = val[0], val[2] }
  |  objectkey EQUAL STRING
       { result = val[0], val[2] }
  |  objectkey EQUAL object
       { result = val[0], val[2] }
  |  objectkey EQUAL list
       { result = val[0], val[2] }
  |  block
       { result = val[0] }
  ;

  block:
     block_id object
       { result = val[0], val[1] }
  |  block_id block
       { result = val[0], {val[1][0] => val[1][1]} }
  ;

  block_id:
     IDENTIFIER
       { result = val[0] }
  |  STRING
       { result = val[0] }
  ;

  list:
     LEFTBRACKET listitems RIGHTBRACKET
       { result = val[1] }
  |  LEFTBRACKET RIGHTBRACKET
       { return }
  ;

  listitems:
     listitem
       { result = [val[0]] }
  |  listitems COMMA listitem
       { result = val[0] << val[2] }
  |  listitems COMMAEND
       { result = val[0] }
  ;

  listitem:
     number
       { result = val[0] }
  |  STRING
       { result = val[0] }
  ;

  number:
     NUMBER
       { result = val[0] }
  |  FLOAT
       { result = val[0] }
  ;


end

---- header
require './lexer'

---- inner
  #//
  #//       HCL is unclear on what one should do when duplicate
  #//       keys are encountered.
  #//
  #//       from decoder.go: if we're at the root or we're directly within
  #//                        a list, decode  to hashes, otherwise lists
  #//
  #//       from object.go:  there is a flattened list structure
  #//
  def flatten_objectlist(list)
    list.each_with_object({}) do |a, h|
      h[a.first] =
        case a.last
        when Hash
          (h[a.first] || {}).update(a.last)
        else
          h[a.first] = a.last
        end
    end
  end


  def on_error(error_token_id, error_value, value_stack)
    header = "parse error found on value: #{error_value}"
    raise Racc::ParseError, header
  end


  def parse(input)
    @lexer = HCLLexer.new.lex(input)
    do_parse
    return @result
  end


  def next_token
    @lexer.shift
  end
