require 'sinatra'

set :port, 15672
set :logging, true

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['cat', 'meow']
  end
end

# ============================================================
# GET
get '/greeting/get/smurf' do
  sleep 0.2
  'good'
end

get '/greeting/get/fail' do
  sleep 0.2
  status 400
end

get '/greeting/get/protected' do
  sleep 0.2
  protected!
  'good'
end

# ============================================================
# DELETE
delete '/greeting/delete/smurf' do
  sleep 0.2
  'good'
end

delete '/greeting/delete/protected' do
  sleep 0.2
  protected!
  status 201
end

# ============================================================
# POST
post '/greeting/post/smurf' do
  sleep 0.2
  protected!
  request.body.rewind
  data = JSON.parse request.body.read

  if data['name'] == 'i am a post' && data['age'] == 425
    status 204
    'good'
  else
    status 402
    'bad'
  end
end

# ============================================================
# PUT
put '/greeting/put/smurf' do
  sleep 0.2
  protected!
  request.body.rewind
  data = JSON.parse request.body.read

  if data['name'] == 'i am a put' && data['age'] == 525
    status 203
    'good'
  else
    status 405
    'bad'
  end
end
