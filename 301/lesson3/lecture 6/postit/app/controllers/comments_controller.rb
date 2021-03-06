class CommentsController < ApplicationController
  before_action :set_post
  before_action :require_user

  def vote
    comment = Comment.find(params[:id])
    vote = Vote.create(vote: params[:vote], creator: current_user, voteable: comment)

    if vote.valid?
      flash[:notice] = "success vote"
    else
      flash[:error] = "error vote"
    end

    redirect_to :back
  end

  def create
    @comment = @post.comments.build(params.require(:comment).permit(:body))

    #obj to obj, id to id
    #virtual attr creator to current_user obj
    @comment.creator = current_user

    if @comment.save
      flash[:notice] = "Saved comment"
      redirect_to post_path(@post)
    else
      flash[:error] = @comment.errors.full_messages
      redirect_to post_path(@post)
    end
  end

  private
  def set_post
    @post = Post.find(params[:post_id])
  end
end