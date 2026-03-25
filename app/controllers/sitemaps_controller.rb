class SitemapsController < ApplicationController
  def show
    @episodes = Episode.published

    respond_to do |format|
      format.xml
    end
  end
end
