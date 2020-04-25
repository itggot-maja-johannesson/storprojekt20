require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

before do
    # Connect to database
    @db = SQLite3::Database.new('db/Blocket.db')
    @db.results_as_hash = true

    session[:user_id] = 1

    # if session[:user_id]
    #     @user = db.execute("SELECT (id, username) WHERE id=?"[session[:user_id]]).first
    # end
end

get('/') do 
    slim(:'index')
end

get('/register') do
    slim(:'users/new')
end

post('/register') do
    username = params["username"]
    password = params["password"]
    password_confirmation = params["confirm_password"]

    register_account(username, password, password_confirmation)
end

get('/login') do
    slim(:'users/index')
end

post('/login') do
    username = params["username"]
    password = params["password"]

    login_account(username, password)
end

get('/postlayout') do
    view_posts()
    slim(:'posts/index')
    slim(:'posts/new')
end

post('/postlayout') do
    upload_post()
    redirect('/postlayout')
end

post('/delete_post/:id') do
    delete_post()
    redirect('/postlayout')
end

get('/edit_post/:id') do
    show_edit_post()
end

post('/edit_post/:id') do
    edit_post()
end

get('/youraccount') do
    slim(:'users/show')
end

post('/youraccount') do
    username = params["username"]
    redirect('/youraccount')
end

post('/add_comment/:id') do
    comment = params["comment"]
    post_id = params["id"]
    
    post_comment(comment, post_id)
    redirect('/postlayout')
end

post('/delete_comment/:id') do
    delete_comment()
    redirect('/postlayout')
end