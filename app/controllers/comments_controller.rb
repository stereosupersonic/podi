class CommentsController < ApplicationController
  def index
    @episode = Episode.find(params[:episode_id])
    @comments = Comment.where("episode_id = #{params[:episode_id]}").order('created_at desc')
    @count = Comment.all.select { |c| c.episode_id.to_s == params[:episode_id] }.size
    @spam = Comment.where("status = 'spam'")
    @has_comments = @comments.present?
  end

  def create
    @episode = Episode.find(params[:episode_id])
    @comment = Comment.new(params.require(:comment).permit!)
    @comment.episode_id = params[:episode_id]
    @comment.status = 'pending'
    @comment.author_email = params[:comment][:author_email]
    @token = SecureRandom.hex(20)

    if @comment.save
      CommentMailer.new_comment(@comment, @token).deliver_now
      redirect_to episode_comments_path(@episode), notice: 'thanks'
    else
      render :index
    end
  rescue
  end

  def approve
    comment = Comment.find(params[:id])
    comment.approve_and_notify!
    redirect_to episode_comments_path(comment.episode_id)
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.destroy
    redirect_to episode_comments_path(params[:episode_id])
  end
end
