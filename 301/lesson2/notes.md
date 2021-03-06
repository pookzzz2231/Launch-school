# Form

* Rails comes with it owns csurf hidden input which prevent from forgery.  

* Best way to create **CRUD** form in rails is **'model-backed forms helpers'**  

* when submitted, form will generate   
params = {..., "instance" => {"model_attr => "value" }, ..}  

* the parameter passed in each method needs to be co-response
  with the @instance's Model attributes, virtual attributes or column name for mass assignment when form is submitted; create action.

```erb
<!--@instance needs to be defined in controller#new action-->
<%= form_for @instance do |f| %>
  <!--the parameter passed in each method needs to be co-response
  with the Model attributes, virtual attributes, column name-->
  <%= f.label :title %>
  <%= f.text_field :title %>
  <br>
  <%= f.submit "Create", class: "className" %>
<% end %>
```

* Rails params will take the name of the instance as a key then assign form value from form input, { ..., post => {...} }

* Inside the params instance name **post**, the value will be a key value pair of mass assignment attr and the input value from the form

* rails form helper match key value from the form ~> **post[:title] => :title**

* the value for instances name need to be match with mass assignment only

```erb
<!--params will assign {post => {...}} as one of params key, value-->
<%= form_for @post do |f| %>
  <%= f.label :title %>
  <!--rails will assign post[:title] => :title for params-->
  <%= f.text_field :title %>
<% end %>
```

## Strong parameter 
* move mass-assignment protection out of the model and into the controller where it belongs.  

* an interface for protecting attributes from mass assignment unless whitelisted.

### Form create
* Get attributes from form with **"params"**

* Use **"require"** method to return obj value ~> {title: "", url: "", creator: ""}

* Use **"permit"** method to whitelisted params.

```ruby
#Controller
class PostsController < ApplicationController
#...some code
  #GET
  def new
    @post = Post.new
  end

  #POST
  def create
    #will mass assign
    @post = Post.new(post_params)

    if @post.save #returns true
      #assign notice key = string in flash obj
      flash[:notice] = "Post was created"
      redirect_to posts_path
    else
      #if failed, return false, will render the new template
      render :new
    end
  end

#DRY by defining strong parameter in private method
  private
  def post_params
    #require post obj key
    #require returns post's value, {title: "", url: "", creator: ""}
    #permit to whitelisted params
    params.require(:post).permit(:title, :url, :creator)

    #whitelisted all
    <!--params.require(:post).permit!-->
  end
end
```

> However the url will not go back to "/posts/new".  For redirect to "/posts/new" if failed to submit the form and show errors, use **'redirect_to'** with **flash**

> flash is rails way to pass primitive(String, array, hash) between action

```ruby
  def new
    #if errors occurs when posted from create action
    #flash[:error] is equal to errors arrays which contains errors messages from action#create
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      flash[:success] = "Post created!"
      redirect_to posts_path
    else
      #flash is rails way to pass primitive(String, array, hash) between action
      #assign flash[:error] to @post.errors.full_messages which contains errors array when POST
      flash[:error] = @post.errors.full_messages
      #Redirect back to form
      redirect_to new_post_path
    end
  end
```

```erb
<!--_messages.html.erb-->
<% flash.each do |name, msg| %>
  <% if msg.is_a?(String) %>
    <div class="alert alert-<%= name == "notice" ? "success" : "error" %>">
      <a class="close" data-dismiss="alert">&#215;</a>
      <%= content_tag :div, msg, :id => "flash_#{name}" %>
    </div>
  <% end %>
  <% if msg.is_a?(Array) %>
    <% msg.each do |m| %>
      <li class="alert alert-danger">
        <%= m %>
      </li>
    <% end %>
  <% end %>
<% end %>
```

## Validate input

* Validate in Model layer for displaying error messages.
```ruby
#Model
class Post < ActiveRecord::Base
  #...some code

  # if validate fail, will returns false
  # then error messages array can be access through
  # @instance.errrors.full_messages
  validate :title, presence: true, length: {minimum: 5}, uniqueness: true
end
```

```erb
<!--in form template-->
<% if @post.errors.any? %>
  <% @post.errors.full_messages.each do |msg| %>
    <li><%= msg %></li>
  <% end %>
<% end %>
```

* if error, class "field_with_errors" will be added to error input ~> add style to specify error input.

### Form edit & update 
* IF the obj is existing obj passed in form_for, rails form helper will get attributes, display attributes and map to update action "/controller/id".

* Rails find the update action by creating hidden input which has '_method' attribute pointed to HTTP verb.

```ruby
#Controller
class PostsController < ApplicationController
#...some code
  #execute method before specified action
  before_action :set_post, only: [:show, :edit, :update]

  def show
  end

  #GET
  def edit
  end

  #PATCH
  def update
    if @post.update(post_params)
      flash[:notice] = "The post is updated"
      redirect_to post_path(@post)
    else
      render :edit
    end
  end

  private
  def post_params
    params.require(:post).permit!
  end

  def set_post
    @post = Post.find(params[:id])
  end
end
```

### nested routes

* For form POST to nested route eg. ~> "/post/:id/comments"

* define nested route in routes.rb

```ruby
  resources :posts, except: [:destroy] do
    resources :comments, only: [:create]
  end
```

* define comment instance to show form in parent action#show

```ruby
#Post Controller
class PostsController < ApplicationController
  before_action :set_post, only: [:show]

  #...some code

  #GET FORM for comment in post#show action
  def show
    # @post is existing
    # @comment need to be new to generate the new form in template
    @comment = Comment.new
  end

  private
  #...some code

  def set_post
    @post = Post.find(params[:id])
  end
end
```

* define POST url, create#action in comments controller

```ruby
#Comments controller
class CommentsController < ApplicationController
  #POST comment form
  def create
    #in nested form, parent_id always have name prepended
    #check with binding pry or form input
    @post = Post.find(params[:post_id])

    #equivalent to
    #@comment = Comment.new(...)
    #@comment.post = @post
    @comment = @post.comments.build.(params.require(:comment).permit!)

    @comment.user_id = Creator.first
    @comment.user = User.first #temp fix

    if @comment.save
      flash[:notice] = "Add comment"
      redirect_to post_path(@post)
    else
      <!--render template file-->
      render "posts/show"
    end
end
```

* show comment form in "/posts/:id/comments"

* need array of nested instance to match url for POST in comment form helper ~> <%= form_for [@post, @comment] do |f| %>

```erb
<!--/posts/show.html.erb-->
<!--from show action
@post is existing obj, @comment is new obj-->
<!--comment form POST to /post/:id/comments-->
<%= form_for [@post, @comment] do |f| %>
  <%= f.label :body %>
  <%= f.text_area :body, :id => "someId", size: "5x5" %>
  <br>
  <%= f.submit "Create", class: "some class" %>
<% end %>
```
* show comments for posts/:id

```erb
<!--/posts/show.html.erb-->
<%= @post.comments each do |c| %>
  <%= c.body %>
<% end %>
```

### link_to helper
* Is a_tag generator in erb template, link_to('name', url, class: "class", data-attr => "data")

* for multiple data attributes use 
{ data: { foo: "bar" } }

```erb
  <%= link_to 'link_name', url_path(path), class: "someClass", 'data-attr' => 'data' %>
```

* for a_tag with html element inside use link_to helper then pass a html block within

```erb
<% link_to(url_path) do %>
  <!-- insert html etc here eg: -->
  <span class="icon">Icon</span>
<% end %>
```

* pass in erb inside erb tag, eg: create breadcrumbs

* Call html_safe to pass as html inside erb tag

```erb
<% breadcrumb = link_to('All Posts', posts_path) + " &raquo; #{@category.name}".html_safe %>
<%= render 'shared/content_title', title: breadcrumb %>
<!--result as: All posts >> cat_name-->
```

### model_ids helper method virtual attribute for M:M
* To submit multiples value as array in form params, name needs to end with '[]', eg:

```erb
<!--params will create {..., options => ["1", "2"]}-->
<select multiple='multiple' name='options[]'>
  <option value="1">1</option>
  <option value="1">2</option>
</select>
```

*  get all ids association ~> model_ids

```ruby
  #getter
  @post.category_ids # returns [1, 2]
  
  #setter
  @post.category_ids = [3] # returns [3]
```

* form_helper check_boxes ~> submmit all values in array through key category_ids which equal virtual attr for M:M

```erb
<!--...some code-->
<%= f.collection_check_boxes :category_ids, Category.all, :id, :name do |cb| %>
  <% cb.label(class: "checkbox inline") {cb.check_box(class: "checkbox") + cb.text} %>
<% end %>
```

* define strong parameter to allow arrays in controller

```ruby
# posts_controller
#...some code

private
def post_params
  #define strong parameter for arrays ~> category_ids
  params.require(:post).permit(:title, :url, :description, category_ids: [])
end
```

### view helper
* all view helpers located at **'/helpers/application_helper.rb'**

```ruby
module ApplicationHelper
  def display_datetime(dt)
    dt.strftime("%m/%d/%Y %l:%M%P %Z")
  end
end
```

* include method in erb view
```erb
  <%= display_datetime(post.created_at) %>
```