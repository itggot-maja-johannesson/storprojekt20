require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

include Model

# Connects to the database 
#
before do
    @db = connect_to_database('db/Blocket.db')
end

# Display landing page
#
get('/') do 
    slim(:'index')
end

# Display registration page
#
get('/register') do
    slim(:'users/new')
end

# Register user and logs in, and updates the session
# 
# @param [String] username, The username
# @param [String] password, The password
# @param [String] password_confirmation, The repeated password
#
# @see Model#register_account
post('/register') do
    username = params["username"]
    password = params["password"]
    password_confirmation = params["confirm_password"]
    results = register_account(username, password, password_confirmation)

    if results == true
        session[:user_error] = ""
        session[:user_id] = login_account(username, password)
        redirect('/posts')
    else
        session[:user_error] = results
        redirect('/register')
    end
end

# Display login page
#
get('/login') do
    slim(:'users/index')
end

# Attempts to login and updates the session
#
# @param [String] username, The username
# @param [String] password, The password
# 
# @see Model#login_account
post('/login') do
    username = params["username"]
    password = params["password"]
    results = login_account(username, password)

    if !session[:time_start] && results.is_a?(Integer)
        session[:user_id] = results
        redirect('/posts')
    else

        if !!session[:time_start]

            timer = timer(session[:time_start], 10)
            session[:time_start] = nil if timer.first
            session[:user_error] = timer.last if !timer.first

            if !session[:time_start] && results.is_a?(Integer)
                session[:user_id] = results
                redirect('/posts')
            end
        else
            session[:time_start] = results.last
            session[:user_error] = results.first
        end
        redirect("/login")
    end
end

# Logs out user
#
post('/logout') do 
    session.destroy
    redirect('/')
end

# Display posts page 
# 
# @see Model#view_post
get('/posts') do
    view_posts()
    slim(:'posts/new')
end

# Creats a post
#
# @param [String] title, The title of the post
# @param [String] specification, The text of the post
# @param [String] cat_1, categorie 1 of the post 
# @param [String] cat_2, categorie 2 of the post 
# @param [String] cat_3, categorie 3 of the post 
# @param [String] cat_4, categorie 4 of the post 
# @param [String] cat_5, categorie 5 of the post 
# @param [String] price, The price of the post
# @param [Sinatra::IndifferentHash] file, The picture of the post
#
# @see Model#upload_post
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

# Deletes post
#
# @param [String] :id, The id of the post
#
# @see Model#delete_post
post('/posts/:id/delete') do
    delete_post(params["id"], session[:user_id])
    redirect('/posts')
end

# Displays edit post page
#
# @param [String] :id, The id of the post
#
# @see Model#show_edit_post
get('/posts/:id/edit') do
    results = show_edit_post(session[:user_id], params) 
    if results == true
        slim(:'posts/edit')
    else
        redirect('/posts')
    end
end

# Edists post
#
# @param [String] title, The title of the post
# @param [String] specification, The text of the post
# @param [String] cat_1, categorie 1 of the post 
# @param [String] cat_2, categorie 2 of the post 
# @param [String] cat_3, categorie 3 of the post 
# @param [String] cat_4, categorie 4 of the post 
# @param [String] cat_5, categorie 5 of the post 
# @param [String] price, The price of the post
# @param [Sinatra::IndifferentHash] file, The picture of the post
# @param [String] :id, The id of the post
# 
# @see Model#edit_post
post('/posts/:id/edit') do
    results = ""
    results = edit_post(params, session[:user_id]) if session[:user_id]
    if results == true
        session[:post_error] = ""
        redirect('/posts')
    else
        session[:post_error] = results
        redirect("/posts/#{params[:id]}/edit")
    end
end

# Displays your account page
#
# @param [String] :id, The id of the user
#
get("/users/:id") do
    slim(:'users/show')
end

# Comments on post
#
# @param [String] comment, The text of the comment
# @param [String] :id, The id of the post
#
# @see Model#post_comment
post('/comments/:id/add') do 
    comment = params["comment"]
    post_id = params["id"]
    
    post_comment(comment, post_id, session[:user_id]) if session[:user_id]
    redirect('/posts')
end

# Deletes comment on post
#
# @param [String] :id, The id of the comment
#
# @see Model#delete_comment
post('/comments/:id/delete') do
    delete_comment(params["id"])
    redirect('/posts')
end