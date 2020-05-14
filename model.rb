require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

def connec_to_database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def register_account(username, password, password_confirmation)

    result = @db.execute("SELECT id FROM users WHERE username=?", username)

    if result.empty? 
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            @db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password_digest])
            return true
        else
            return "Passwords don't match!"
        end
    else
        return "Sorry, username already taken!"
    end

end

def login_account(username, password)

    result = @db.execute("SELECT * FROM users WHERE username=?", username)

    if result.empty?
        return "No such username!"
    end

    user_id = result.first["id"]
    password_digest = result.first["password"]

    timed_tries = []
    time = 0

    if BCrypt::Password.new(password_digest) == password
        return user_id
    else
        return "Invalid Credentials!"
        timed_tries << Time.now.to_i 
        if timed_tries.length > 5
            if Time.now.to_i - timed_tries[0] < 10
                time = Time.now.to_i
                timed_tries = []
                return "You've tried too many passwords in too short time, try again in 5 minutes"
            end
            timed_tries.shift
        end
    end
end

def view_posts()
    posts = @db.execute("SELECT * FROM posts")
    @categories = @db.execute("SELECT * FROM categories")

    comments = @db.execute("SELECT * FROM comments").each do |comment|
        comment = comment["username"] = @db.execute("SELECT username FROM users WHERE id=?", [comment["user_id"]]).first["username"] 
    end

    @posts = posts.each do |post|
        post["username"] = @db.execute("SELECT username FROM users WHERE id=?", [post["user_id"]]).first["username"]
        post["comments"] = comments.select { |comment| comment["post_id"] == post["id"] }
        
        post["categories"] = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[post["id"]]).map { |cat| p @db.execute("SELECT name FROM categories WHERE id=?",[cat["categorie_id"]]).first["name"] }
    end

    @posts.first
end

def upload_post(params, user_id)
    case false
        when !!user_id
            return "You need to be logged in"

        when !params[:title].empty?
            return "You need to have a title"

        when !params[:specification].empty?
            return "You need to have a text"

        when !params[:price].empty?
            return "You need to add a price"

        when !!params[:file]
            return "You need to add a picture"
    end

    title = params[:title]
    text = params[:specification]
    price = params[:price]

    cat_ids = params.to_a.select { |param| param[0].include?("cat_") }
    cat_ids = cat_ids.map { |cat_id| cat_id = cat_id[0].split("").select.with_index { |_, i| i > 3 }.join.to_i }

    path = File.join("./public/uploaded_pictures/", params[:file][:filename])
    File.write(path, File.read(params[:file][:tempfile]))    

    @db.execute("INSERT INTO posts(user_id, title, text, picture_source, price) VALUES (?,?,?,?,?)", [user_id, title, text, path, price])
    post_id = @db.execute("SELECT id FROM posts").last["id"].to_i
    cat_ids.each { |cat_id| @db.execute("INSERT INTO posts_categories (post_id, categorie_id) VALUES (?,?)", [post_id, cat_id]) }
    
    return true
end

def delete_post(id, user_id)
    @db.execute("DELETE FROM posts WHERE id=?", [id])
end

def show_edit_post(user_id, params)
    @post = @db.execute("SELECT * FROM posts WHERE id=?",[params["id"]])[0]
    @post["categories"] = @db.execute("SELECT * FROM posts_categories WHERE post_id=?",[params["id"]])
    
    posts_cat_ids = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[params["id"]]).map{ |cat| cat.to_a }.flatten.select { |cat| cat.is_a? Integer }
    @categories = @db.execute("SELECT * FROM categories").each { |categorie| categorie["checked"] = posts_cat_ids.include?(categorie["id"]) }

    return @post["user_id"] == user_id
end

def edit_post(params, user_id)
    case false
        when !!user_id
            return "You need to be logged in"

        when !params[:title].empty?
            return "You need to have a title"

        when !params[:specification].empty?
            return "You need to have a text"

        when !params[:price].empty?
            return "You need to add a price"
    end

    path = ""
    
    if !params[:file]
        @db.execute("SELECT picture_source FROM posts WHERE id=?", [params["id"]])
    else
        path = File.join("./public/uploaded_pictures/", params[:file][:filename])
        File.write(path, File.read(params[:file][:tempfile]))
    end

    @db.execute("UPDATE posts SET
        title = ?,
        text = ?,
        picture_source = ?,
        price = ?
        WHERE id=?",[params[:title], params[:specification], path, params[:price], params[:id]])

    return true
end

def post_comment(comment, post_id, user_id)
    @db.execute("INSERT INTO comments (user_id, text, post_id) VALUES (?,?,?)", [user_id, comment, post_id])
end

def delete_comment(id)
    @db.execute("DELETE FROM comments WHERE id=?", [id])
end