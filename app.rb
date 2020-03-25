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

get('/postlayout') do
    slim(:'Posts/index')
end

post('/login') do
    db = connect_to_db('db/Blocket.db')
    username = params["username"]
    password = params["password"]

    result = db.execute("SELECT ID FROM User WHERE Username=?", username)

    if result.empty?
        set_error("Invalid Credentials")
        redirect("/error")
    end

    user_id = result.first["ID"]
    password_digest = result.first["password_digest"]

    if BCrypt::Password.new(password_digest) == password

    end
    # db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password])
    redirect('/postlayout')
end

get('/register') do
    slim(:'users/new')
end

post('/register') do
    db = connect_to_db('db/Blocket.db')
    username = params["username"]
    password = params["username"]

    password_confirmation = params["confirm password"]

    result = db.execute("SELECT ID FROM User WHERE Username=?", username)

    if result.empty? 
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            p password_digest
            db.execute("INSERT INTO User(Username, Password) VALUES (?,?)", [username, password_digest])
            redirect('/postlayout')
        else
            set_error("Password don't match")
            redirect('/error')
        end
    else
        set_error("Username already exists")
        redirect('/error')
    end
end

