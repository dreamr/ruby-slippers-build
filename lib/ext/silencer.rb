require 'stringio'

module Silencer
  %w(stderr stdout).each do |output|
    class_eval <<-EOS
      def silence_#{output}
        #{output} = StringIO.new
        $#{output} = #{output}
        yield
        return #{output}.string
      ensure
        $#{output} = #{output.upcase}
      end
    EOS
  end
end