require 'listen'

class PostCSS
  def initialize(app)
    @app = app
    @compire_required = false

    @listener = Listen.to('./app/views/') do |modified, added, removed|
      @compire_required = true
    end
    puts "PostCSS listen start"
    @listener.start
  end

  def call(env)
    if @compire_required
      puts "View file changed. start tailwindcss compile"
      puts `yarn build`
      @compire_required = false
    end

    @app.call(env)
  end
end
