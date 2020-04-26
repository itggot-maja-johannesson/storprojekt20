require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

before do
    @db = connec_to_database('db/Blocket.db')
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
    results = register_account(username, password, password_confirmation)
    p results
    if results == true
        session[:user_error] = ""
        session[:user_id] = login_account(username, password) 
        redirect('/posts')
    else
        session[:user_error] = results
        redirect('/register')
    end

end

get('/login') do
    slim(:'users/index')
end

post('/login') do
    username = params["username"]
    password = params["password"]

    results = login_account(username, password)
    if results.is_a? Integer
        session[:user_id] = results
        redirect('/posts')
    else
        session[:user_error] = results
        redirect("/login")
    end
end

post('/logout') do 
    session.destroy
    redirect('/')
end

get('/posts') do
    view_posts()
    slim(:'posts/index')
    slim(:'posts/new')
end

post('/posts') do
    results = upload_post(params, session[:user_id])
    p results
    if results == true
        session[:post_error] = ""
    else
        p results
        session[:post_error] = results
    end
    redirect('/posts')
end

post('/posts/delete/:id') do
    delete_post(params["id"])
    redirect('/posts')
end

get('/posts/edit/:id') do
    results = show_edit_post(session[:user_id]) 
    if results == true
        slim(:'posts/edit')
    else
        redirect('/posts')
    end
end

post('/posts/edit/:id') do
    results = ""
    results = edit_post(params, session[:user_id]) if session[:user_id]
    if results == true
        session[:post_error] = ""
        redirect('/posts')
    else
        session[:post_error] = results
        redirect("/posts/edit/#{params[:id]}")
    end
end

get("/users/:id") do
    slim(:'users/show')
end

post('/comments/add/:id') do 
    comment = params["comment"]
    post_id = params["id"]
    
    post_comment(comment, post_id, session[:user_id]) if session[:user_id]
    redirect('/posts')
end

post('/comments/delete/:id') do
    delete_comment(params["id"])
    redirect('/posts')
end