require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

def register_account(username, password, password_confirmation)

    result = @db.execute("SELECT id FROM users WHERE username=?", username)

    if result.empty? 
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            @db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password_digest])
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

def login_account(username, password)

    result = @db.execute("SELECT * FROM users WHERE username=?", username)

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
    # @db.execute("INSERT INTO users(username, password) VALUES (?,?)", [username, password])
    # redirect('/postlayout')

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

        # p posts_cat_ids = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[post["id"]]).map{ |cat| cat.to_a }.flatten.select { |cat| cat.is_a? Integer }
        
        post["categories"] = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[post["id"]]).map { |cat| p @db.execute("SELECT name FROM categories WHERE id=?",[cat["categorie_id"]]).first["name"] }
        
        # post["categories"] = @categories.select { |categorie| posts_cat_ids.include?(categorie["id"]) == true }
    end

    p @posts.first

    # posts_cat_ids = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[params["id"]]).map{ |cat| cat.to_a }.flatten.select { |cat| cat.is_a? Integer }
    # @categories = @db.execute("SELECT * FROM categories").each { |categorie| categorie["checked"] = posts_cat_ids.include?(categorie["id"]) }
end

def upload_post()
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
        user_id = session[:user_id]
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
    end
end

def delete_post()
    @db.execute("DELETE FROM posts WHERE id=?", [params["id"]])
end

def show_edit_post()
    @post = @db.execute("SELECT * FROM posts WHERE id=?",[params["id"]])[0]
    @post["categories"] = @db.execute("SELECT * FROM posts_categories WHERE post_id=?",[params["id"]])
    
    posts_cat_ids = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[params["id"]]).map{ |cat| cat.to_a }.flatten.select { |cat| cat.is_a? Integer }
    @categories = @db.execute("SELECT * FROM categories").each { |categorie| categorie["checked"] = posts_cat_ids.include?(categorie["id"]) }

    if @post["user_id"] == session[:user_id]
        slim(:'posts/edit')
    else
        redirect('/postlayout')
    end
end

def edit_post()
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

    end

    if session[:post_error]
        redirect("/edit_post/#{params[:id]}")
    else
        redirect('/postlayout')
    end
end

def post_comment(comment, post_id)
    @db.execute("INSERT INTO comments (user_id, text, post_id) VALUES (?,?,?)", [session[:user_id], comment, post_id])
end

def delete_comment()
    @db.execute("DELETE FROM comments WHERE id=?", [params["id"]])
end