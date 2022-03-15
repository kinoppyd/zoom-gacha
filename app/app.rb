module ZoomGacha
  class App < Padrino::Application
    register SassInitializer
    use ConnectionPoolManagement
    register Padrino::Mailer
    register Padrino::Helpers
    enable :sessions

    use OmniAuth::Builder do
      provider :google_oauth2,
        ENV['GOOGLE_CLIENT_ID'],
        ENV['GOOGLE_CLIENT_SECRET'],
        {
          scope: 'userinfo.email, userinfo.profile',
          prompt: 'select_account',
          image_aspect_ratio: 'square',
          image_size: 50,
          callback_path: '/auth/callback'
        }
    end
    OmniAuth.config.allowed_request_methods = %i[get]

    get "/" do
      if Padrino.env == :development || session[:email]
        @email = session[:email] || 'test'
        @gachas = Gacha.all.order(created_at: :desc).includes(:user).limit(20)
        @csrf_token = Rack::Protection::AuthenticityToken.token(env['rack.session'])
        render 'index'
      else
        render 'login'
      end
    end

    get '/login' do
      redirect_to '/auth/google_oauth2'
    end

    get '/logout' do
      session[:email] = nil
      redirect_to '/'
    end

    post "/gacha" do
      begin
        u = User.find_by(email: session[:email])
      rescue StandardError
        u = User.first
      end

      begin
        zoom = ZoomClient.new
        meeting_id = params["meeting_id"].gsub(/ /, "").gsub(/-/, "")
        meeting = Meeting.find_or_create_by!(meeting_id: meeting_id)
        name = zoom.meeting_name(meeting_id)
        meeting.update!(name: name)
        gacha = HeadlessGachaClient.new.gacha(zoom.users_list(meeting_id)).env.url.to_s
        Gacha.create!(user: u, title: name, result: gacha, meeting: meeting)
        redirect_to '/'
      rescue Zoom::Error => zoom_e
        @error = zoom_e.message
        render 'errors/zoom_error'
      end
    end

    %w(get post).each do |method|
      send(method, "/auth/callback") do
        auth_hash = env['omniauth.auth']
        if auth_hash["extra"]["id_info"]["email"].end_with?("@smarthr.co.jp")
          @user = User.find_or_create_from_auth_hash(auth_hash)
          session[:email] = @user.email
          redirect_to '/'
        else
          redirect_to '/'
        end
      end
    end

    ##
    # Caching support.
    #
    # register Padrino::Cache
    # enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache.new(:LRUHash) # Keeps cached values in memory
    # set :cache, Padrino::Cache.new(:Memcached) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Memcached, :server => '127.0.0.1:11211', :exception_retry_limit => 1)
    # set :cache, Padrino::Cache.new(:Memcached, :backend => memcached_or_dalli_instance)
    # set :cache, Padrino::Cache.new(:Redis) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Redis, :host => '127.0.0.1', :port => 6379, :db => 0)
    # set :cache, Padrino::Cache.new(:Redis, :backend => redis_instance)
    # set :cache, Padrino::Cache.new(:Mongo) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Mongo, :backend => mongo_client_instance)
    # set :cache, Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options.
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    #

    ##
    # You can manage errors like:
    #
    #   error 404 do
    #     render 'errors/404'
    #   end
    #
    #   error 500 do
    #     render 'errors/500'
    #   end
    #
  end
end
