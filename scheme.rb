
def parse(input)
    read(tokenize(input))
end

def tokenize(input)
    input.gsub(/\(/, ' ( ').
    gsub(/\)/, ' ) ').
    strip.
    split
end

def read(tokens)
    
    if tokens.size == 0
        raise SyntaxError, 'Unexpected EOF'
    end
    
    token = tokens.shift
    if token == '('
        li = []
        li.push(read(tokens)) while tokens.first != ')'
        tokens.shift # remove ')'
        return li
    elsif token == ')'
        raise SyntaxError, 'Unexpected closing parenthesis'
    else
        return atom(token)
    end
end

def atom(token)
    case token
    when /\A[+-]?\d+$\Z/
      { :type => :int, :value => token.to_i }
    when /\A[+-]?\d+\.\d+\Z/
      { :type => :float, :value => token.to_f }
    when /\A\S*\Z/
      { :type => :symbol, :value => token }
    else
      raise SyntaxError, "Invalid syntax near #{token}"
    end
end
