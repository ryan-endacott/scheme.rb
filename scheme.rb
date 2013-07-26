class Env < Hash
    
    @@built_in_functions = {
        :if =>
            lambda do |env|
                return lambda do |cond, conseq, alt|
                    if cond
                        conseq
                    else
                        alt
                    end
                end
            end,
        :+ =>
            lambda do |env|
                lambda do |*args|
                    args.inject(&:+)
                end
            end     
    }
    
    def initialize(global = true, parent = @@built_in_functions)
        @global = global
        @parent = parent
    end
    
    def [](key, child_env = self)
        if key? key
            super(key)
        elsif @parent[key].nil?
            raise UndefinedError, "Variable #{key} is undefined."
        elsif @global
            @parent[key].call(child_env)
        else
            @parent[key, child_env]
        end
    end
    
    def new_child
        Env.new(false, self)
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
        token.to_i
    when /\A[+-]?\d+\.\d+\Z/
        token.to_f
    when /\Anull\Z/
        nil
    when /\A\S*\Z/
        token.to_sym
    else
      raise SyntaxError, "Invalid syntax near #{token}"
    end
end

$global_env = Env.new

def interpret(input, env = $global_env)
    if input.is_a? Symbol
        env[input]
    elsif input.is_a? Array # Builtin function
        if input.first == :define # Special case for define
            env[input[1]] = interpret(input[2], env.new_child)
        else
            args = input[1, input.length].map { |i| interpret(i, env.new_child) }
            env[input.first].call(*args)
        end
    else # constant literals, e.g. numbers
        input
    end
end

def lisp(input)
    interpret(parse(input))
end
