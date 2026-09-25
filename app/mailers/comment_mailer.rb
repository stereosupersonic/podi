class CommentMailer < ApplicationMailer
  def new_comment(comment, token)
    @comment = comment
    @token = token
    mail(to: 'admin@podi.dev', subject: 'New comment was posted!')
  end

  def approved(comment)
    @comment = comment
    mail(to: @comment.author_email, subject: 'Your comment is now live')
  end
end
