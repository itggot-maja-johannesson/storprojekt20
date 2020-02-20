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
    username = params["username"]
    password = params["password"]

    # db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password])
    redirect('/login')
end

get('/register') do
    slim(:'users/new')
end

post('/register') do
    db = connect_to_db('db/Blocket.db')
    username = params["username"]
    password = params["username"]
    password_digest = BCrypt::Password.create(plain_text_password)


    redirect('/login')
end