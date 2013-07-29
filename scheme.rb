class Env < Hash
    
    @@built_in_functions = {
        :+ =>
            lambda do |*args|
                args.inject(&:+)
            end,
        :eq? =>
            lambda do |*args|
                args.uniq.size == 1
            end
    }
    
    def initialize(parent = @@built_in_functions)
        @parent = parent
    end
    
    def [](key, child_env = self)
        if key? key
            super(key)
        elsif @parent[key].nil?
            raise UndefinedError, "Variable #{key} is undefined."
        else
            @parent[key]
        end
    end
    
    def new_child(params = nil)
        env = Env.new(self)
        env.merge!(Hash[params]) if params
        env
    end
    
end

class UndefinedError < StandardError; end


def parse(input)
    tokens = tokenize(input)
    if tokens.size > 0
        read(tokens)
    else
        nil
    end
end

def tokenize(input)
    input.gsub(/\(/, ' ( ').
    gsub(/\)/, ' ) ').
    gsub(/;[^\n]*/, ''). # Allow comments
    strip.
    split
end

def read(tokens, depth = 0)
    
    if tokens.size == 0 and depth > 0
        raise SyntaxError, 'Unexpected EOF'
    end
    
    token = tokens.shift
    if token == '('
        li = []
        li.push(read(tokens, depth + 1)) while tokens.first != ')'
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
    when /\A[+-]?\d+$\Z/ # integer
        token.to_i
    when /\A[+-]?\d+\.\d+\Z/ # float
        token.to_f
    when /\Anull\Z/ # null
        nil
    when /\A:\S*\Z/ # lisp symbol ex: 'hi
        token.to_s[1..-1]
    when /\A\S*\Z/ # symbol
        token.to_sym
    else
      raise SyntaxError, "Invalid syntax near #{token}"
    end
end

$global_env = Env.new

def interpret(input, env = $global_env)
    case input
    when Symbol # Variable
        env[input]
    when Array # Function call
        interpret_func(input, env)
    else # constant literals like numbers
        input
    end
end

def interpret_func(input, env)
    func = input.first
    args = input[1..-1]
    case func
    when :define
        if args.first.is_a? Symbol # Naming variable
            name, expr = args
            env[name] = interpret(expr, env.new_child)
        else # Creating function
            params, expr = args
            env[params.shift] = lambda do |*args|
                interpret(expr, env.new_child(params.zip args))
            end
        end
    when :if
        cond, conseq, alt = args
        if cond
            interpret(conseq, env)
        else
            interpret(alt, env)
        end
    when :lambda
        params, expr = args
        lambda do |*args|
            interpret(expr, env.new_child(params.zip args)) # Interpet with params in environment
        end
    when :begin
        args.each do |arg|
            interpret(arg, env.new_child)
        end
    else # Any other function
        # Interpret args first for applicative-order evaluation
        args = args.map { |a| interpret(a, env.new_child) }
        env[func].call(*args)
    end
end

def lisp(input)
    interpret(parse(input))
end

def repl
    puts 'Welcome to scheme.rb!'
    print 'scheme.rb >>'
    loop do
        input = gets
        if input.chomp == 'quit'
            puts 'Quitting scheme.rb!'
            return
        end
        output = lisp(input)
        puts "=> #{output}"
        print 'scheme.rb >>'
    end
end
