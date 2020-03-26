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
   
# post('/users/') do                         Exempel + den övre för att få mindre kod
#     db = connect_to_db('db/todo.db')
#     username = params["username"]
#     password = params["password"]
#     db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password])
#     redirect('/photos')
# end
   

get('/') do 
    slim(:index)
end

get('/login') do
    slim(:'users/index')
end

post('/login') do
    db = connect_to_db('db/Blocket.db')
    db.results_as_hash = true
    username = params["username"]
    password = params["password"]

    result = db.execute("SELECT id FROM users WHERE username=?", username)

    if result.empty?
        sessions[:user_error] = "Invalid Credentials!"
        redirect("/register")
    end

    user_id = result.first["id"]
    password_digest = result.first["password_digest"]

    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        redirect('/postlayout')
    else
        sessions[:user_error] = "Invalid Credentials!"
        redirect("/register")
    end
    # db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password])
    # redirect('/postlayout')
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

get('/postlayout') do
    slim(:'Posts/index')
    slim(:'Posts/new')
end

get('/postlayout') do
    
end


post('/postlayout') do 
    redirect('/postlayout')
end


