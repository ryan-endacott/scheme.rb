class Atom
    
    def initialize(type, value)
        @type = type
        @value = value
    end
    
    def symbol?
        @type == :symbol
    end
    
    def int?
        @type == :int
    end
    
    def float?
        @type == :float
    end
    
end


class Environment < Hash
    
    @@built_in_functions = {}
    
    def initialize(parent = @@built_in_functions)
        @parent = parent
    end
    
    def [](key)
        if key? key
            super
        elsif @parent[key].nil?
            raise UndefinedError, "Variable #{key} is undefined."
        else
            @parent[key]            
        end
    end
    
    def new_child
        Environment.new(self)
    end
    
end

class UndefinedError < StandardError; end


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
        Atom.new(:int, token.to_i)
    when /\A[+-]?\d+\.\d+\Z/
        Atom.new(:float, token.to_f)
    when /\A\S*\Z/
        Atom.new(:symbol, token)
    else
      raise SyntaxError, "Invalid syntax near #{token}"
    end
end

global_env = Environment.new

def interpret(input, env = global_env)
    if input.is_a? Array
        if input.first.symbol?
            env[input]
        
end

def lisp(input)
    interpret(parse(input))
end
