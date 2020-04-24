require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

get('/') do 
    slim(:'index')
end

get('/register') do
    slim(:'users/new')
end

post('/register') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true
    username = params["username"]
    password = params["password"]
    password_confirmation = params["confirm_password"]

    result = db.execute("SELECT id FROM users WHERE username=?", username)

    if result.empty? 
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password_digest])
            redirect('/postlayout')
        else
            session[:user_error] = "Passwords don't match!"
            redirect('/register')
        end
    else
        session[:user_error] = "Sorry, username already taken!"
        redirect('/register')
    end
end

get('/login') do
    slim(:'users/index')
end

post('/login') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true
    username = params["username"]
    password = params["password"]

    p result = db.execute("SELECT * FROM users WHERE username=?", username)

    if result.empty?
        sessions[:user_error] = "Invalid Credentials!"
        redirect("/register")
    end

    user_id = result.first["id"]
    p password_digest = result.first["password"]
    # p BCrypt::Password.new(password_digest)


    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        redirect('/postlayout')
    else
        session[:user_error] = "Invalid Credentials!"
        redirect("/register")
    end
    # db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password])
    # redirect('/postlayout')
end


before('/postlayout') do 
    session[:user_id] = 1
end


get('/postlayout') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true

    posts = db.execute("SELECT * FROM posts")    
    session[:posts] = posts.each { |post| post["username"]=db.execute("SELECT username FROM users WHERE id=?", [post["user_id"]])[0]["username"] }

    slim(:'Posts/index')
    slim(:'Posts/new')
end

post('/postlayout') do 
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true

    p "-------outside!--------"
    
    case false
        when !!session[:user_id]
            session[:post_error] = "You need to be logged in"

        when !params[:title].empty?
            session[:post_error] = "You need to have a title"

        when !params[:specification].empty?
            session[:post_error] = "You need to have a text"

        when !params[:price].empty?
            session[:post_error] = "You need to add a price"

        when !!params[:file]
            session[:post_error] = "You need to add a picture"
    end

    unless session[:post_error]
        p "---------inside!----------"

        p user_id = session[:user_id]
        p title = params[:title]
        p text = params[:specification]
        p price = params[:price]

        params.to_a

        p cat_ids = params.to_a.select { |param| param[0].include?("cat_") }
        p cat_ids = cat_ids.map { |cat_id| cat_id = cat_id[0].split("").select.with_index { |_, i| i > 3 }.join.to_i }

        p "---------inside!----------"

        p path = File.join("./public/uploaded_pictures/", params[:file][:filename])
        File.write(path, File.read(params[:file][:tempfile]))

        db.execute("INSERT INTO posts(user_id, title, text, picture_source, price) VALUES (?,?,?,?,?)", [user_id, title, text, path, price])
        p post_id = db.execute("SELECT id FROM posts WHERE user_id = ?", [user_id])[1]["id"]
        cat_ids.each { |cat_id| db.execute("INSERT INTO posts_categories (post_id, categorie_id) VALUES (?,?)", [post_id, cat_id]) }
    end

    redirect('/postlayout')
end

post('/delete_post/:id') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true
    db.execute("DELETE FROM posts WHERE id=?", [params["id"]])
    
    redirect('/postlayout')
end

before('/edit_post/:id') do 
    session[:user_id] = 1
end

get('/edit_post/:id') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true
    session[:post] = db.execute("SELECT * FROM posts WHERE id=?",[params["id"]])[0]

    p session[:post]["user_id"]
    p session[:user_id]

    if session[:post]["user_id"] == session[:user_id]
        slim(:'Posts/edit')
    else
        redirect('/postlayout')
    end
end

post('/edit_post/:id') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true

    case false
        when !!session[:user_id]
            session[:post_error] = "You need to be logged in"

        when !params[:title].empty?
            session[:post_error] = "You need to have a title"

        when !params[:specification].empty?
            session[:post_error] = "You need to have a text"

        when !params[:price].empty?
            session[:post_error] = "You need to add a price"
    end

    unless session[:post_error]

        path = session[:post]["picture_source"]

        if !!params[:file]
            path = File.join("./public/uploaded_pictures/", params[:file][:filename])
            File.write(path, File.read(params[:file][:tempfile]))
        end

        db.execute("UPDATE posts SET
            title = ?,
            text = ?,
            picture_source = ?,
            price = ?
            WHERE id=?",[params[:title], params[:specification], path, params[:price], params[:id]])

    end

    if session[:post_error]
        redirect("/edit_post/#{params[:id]}")
    else
        redirect('/postlayout')
    end
end

get('/showposts') do
    slim(:'Posts/show')
end

# post('/showposts') do
#     db = connect_to_db('db/Blocket.db')
#     db.results_as_hash = true

#     user_id = session[:user_id]
#     title = params[:title]
#     text = params[:specification]
#     price = params[:price]

#     post = db.execute("SELECT (title, text, price) FROM posts WHERE id=?", id)
#     return post

#     redirect('/postlayout')
# end

# ska kolla om personen har behörighet

# before do
#     session[:user_liked] = {}
#     session[:error] = ""
#     session[:user_id] = 1
#     if session[:user_id] == nil
#         case request.path_info
#         when '/'
#             break     
#         when '/sign_in'
#             break
#         when '/sign_in_user'
#             break
#         when '/create_user'
#             break
#         when '/sign_up'
#             break
#         when '/test'
#             break
#         else
#             session[:error] = "You need to be logged in order to do this"
#             redirect('/login')
#         end    
#     end
# end 

get('/youraccount') do
    slim(:'Users/show')
end

post('/youraccount') do
    db = connect_to_db('db/Blocket.db')
    username = params["username"]

    redirect('/youraccount')
end

get('/add_comment') do
    slim(:'Comments/new')
end

post('/add_comment') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true
    
    case false
        when !!session[:user_id]
            session[:comment_error] = "You need to be logged in"

        when !params[:text].empty?
            session[:comment_error] = "You need to write a comment"
    end

    unless session[:comment_error]

        p user_id = session[:user_id]
        p text = params[:text]

        params.to_a

        File.write(path, File.read(params[:file][:tempfile]))

        db.execute("INSERT INTO comments(user_id, text) VALUES (?,?)", [user_id, text])
        p comment_id = db.execute("SELECT id FROM comments WHERE user_id = ?", [user_id])[1]["id"]
        # något med post_id för att få till 'posts_comments'
    end

    redirect('/postlayout')
end

get('/delete_comment') do 
end

post('/delete_comment') do 
end



