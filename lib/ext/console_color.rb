require 'term/ansicolor'

module ConsoleColor
  include Term::ANSIColor
  
  def puts(msg, color=nil, style=nil)
    return print(color msg, reset, "\n") if color.nil? && style.nil?
    print color, style, msg, reset, "\n"
  end
  
  def notify(msg)
    puts msg, blue
  end
  
  def alert(msg)
    puts msg, red
  end
  
  def gratify(msg)
    puts msg, green
  end
end