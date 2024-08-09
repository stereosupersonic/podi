module Admin
  class SettingsController < BaseController
    def edit
      @setting = Setting.current
    end

    def update
      @setting = Setting.current

      if @setting.update update_params
        redirect_to root_path, notice: "Setting was successfully updated."
      else
        render :edit
      end
    end

    protected

    def update_params
      params.require(:setting).permit(*%i[
                                        title
                                        description
                                        language
                                        seo_keywords
                                        author
                                        owner
                                        email
                                        itunes_category
                                        itunes_language
                                        itunes_sub_category
                                        logo_url
                                        default_episode_artwork_url
                                        about_episode_number
                                        facebook_url
                                        youtube_url
                                        twitter_url
                                        instagram_url
                                        itunes_url
                                        spotify_url
                                        google_url
                                        itunes_url
                                      ])
    end
  end
end
