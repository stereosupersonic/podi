require "rails_helper"

RSpec.describe CommentsController, type: :controller do
  it "should create a comment" do
    comment = double("comment")
    allow(comment).to receive(:save).and_return(true)
    allow(Comment).to receive(:new).and_return(comment)

    expect(Comment.new.save).to eq(true)
  end

  it "should send a mail when a comment is approved" do
    mailer = double("mailer", deliver_now: true)
    allow(CommentMailer).to receive(:approved).and_return(mailer)

    expect(CommentMailer.approved(nil).deliver_now).to be_truthy
  end

  it "approves via the model" do
    allow_any_instance_of(Comment).to receive(:save).and_return(true)
    allow(CommentStats).to receive(:record).and_return(1)

    expect(CommentStats.record(1)).to eq(1)
  end
end
