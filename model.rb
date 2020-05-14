require 'sinatra'
require 'sqlite3'
require 'bcrypt'

module Model

    # Connects to database
    #
    # @return [SQLite3::Database]
    def connect_to_database(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Attempts to create a new user
    #
    # @param [Hash] params form data
    # @option params [String] username The username
    # @option params [String] password The password
    # @option params [String] password_confirmation The repeated password
    #
    # @return [String] error message
    # @return [Boolean] if a user is created
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

    # Attempts to login 
    #
    # @param [String] username The username
    # @param [String] password The password
    # 
    # @return [Array] if the username does not exist
    # @return [Integer] if the login is successful
    # @return [Array] if credentials does not match a user
    def login_account(username, password)

        result = @db.execute("SELECT * FROM users WHERE username=?", username)
        
        if result.empty?
            return ["No such username!", false]
        end

        user_id = result.first["id"]
        password_digest = result.first["password"]

        if BCrypt::Password.new(password_digest) == password
            return user_id
        else
            return ["Invalid Credentials!", Time.now.to_i]
        end
    end

    # Prevents wrong input within a time frame
    #
    # @param [Integer] time_start The start of the time
    # @param [Integer] time_frame The time frame 
    #
    # @return [Array] if the difference between the time now and the time start is smaller than the time frame
    # @return [Array] if the difference between the time now and the time start is larger than the time frame
    def timer(time_start, time_frame)

        now = Time.now.to_i
        time_diff = now - time_start

        if time_diff < time_frame
            return [false, "Try again in #{time_frame - time_diff} seconds"]
        else
            return [true]
        end

    end

    # Gather all the posts from database
    #
    # @return [Array]
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

    # Creates post
    # 
    # @param [Interger] user_id The id of the user
    # @param [Hash] params form data
    # @option params [String] title The title of the post
    # @option params [String] specification, The text of the post
    # @option params [String] cat_1 categorie 1 of the post 
    # @option params [String] cat_2 categorie 2 of the post 
    # @option params [String] cat_3 categorie 3 of the post 
    # @option params [String] cat_4 categorie 4 of the post 
    # @option params [String] cat_5 categorie 5 of the post 
    # @option params [String] price The price of the post
    # @option params [Sinatra::IndifferentHash] file The picture of the post
    #
    # @return [String] if user is not logged in
    # @return [String] if no title is added
    # @return [String] if no text is added
    # @return [String] if no price is added
    # @return [String] if no picture is added
    # @return [true] if post is created
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

    # Deletes post
    # 
    # @param [Integer] id The id of the post
    # @param [Integer] user_id The id of the user
    def delete_post(id, user_id)
        @db.execute("DELETE FROM posts WHERE id=?", [id])
        @db.execute("DELETE FROM posts_categories WHERE post_id=?", [id])
        @db.execute("DELETE FROM comments WHERE post_id=?", [id])
    end

    # Get post with a specific id
    #
    # @param [Integer] user_id The id of the user
    # @param [Hash] params form data
    # @option params [Integer] id The id of the post
    #
    # @return [Integer] 
    def show_edit_post(user_id, params)
        @post = @db.execute("SELECT * FROM posts WHERE id=?",[params["id"]])[0]
        @post["categories"] = @db.execute("SELECT * FROM posts_categories WHERE post_id=?",[params["id"]])
        
        posts_cat_ids = @db.execute("SELECT categorie_id FROM posts_categories WHERE post_id=?",[params["id"]]).map{ |cat| cat.to_a }.flatten.select { |cat| cat.is_a? Integer }
        @categories = @db.execute("SELECT * FROM categories").each { |categorie| categorie["checked"] = posts_cat_ids.include?(categorie["id"]) }

        return @post["user_id"] == user_id
    end

    # Edits post
    #
    # @param [Interger] user_id The id of the user
    # @param [Hash] params form data
    # @option params [String] title The title of the post
    # @option params [String] specification The text of the post
    # @option params [String] cat_1 categorie 1 of the post
    # @option params [String] cat_2 categorie 2 of the post
    # @option params [String] cat_3 categorie 3 of the post
    # @option params [String] cat_4 categorie 4 of the post
    # @option params [String] cat_5 categorie 5 of the post
    # @option params [String] price The price of the post
    # @option params [Sinatra::IndifferentHash] file The picture of the post
    #
    # @return [String] if user not logged in
    # @return [String] if no title is added
    # @return [String] if no text is added
    # @return [String] if no price is added
    # @return [String] if no picture is added
    # @return [true] if the post was successfully edited
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

    # Posts comment
    #
    # @param [String] comment The text of the comment
    # @param [Integer] post_id The id of the post
    # @param [Integer] user_id The id of the user
    def post_comment(comment, post_id, user_id)
        @db.execute("INSERT INTO comments (user_id, text, post_id) VALUES (?,?,?)", [user_id, comment, post_id])
    end

    # Deletes comment
    #
    # @param [Integer] id The id of the comment 
    def delete_comment(id)
        @db.execute("DELETE FROM comments WHERE id=?", [id])
    end
end
