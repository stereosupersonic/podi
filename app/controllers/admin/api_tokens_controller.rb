module Admin
  class ApiTokensController < BaseController
    def index
      @api_tokens = ApiTokenPresenter.wrap current_user.api_tokens.order(created_at: :desc)
    end

    def new
      @api_token = current_user.api_tokens.new
    end

    # Renders instead of redirecting: the plaintext token must not travel through the flash,
    # which is stored in the session cookie.
    def create
      @api_token = ApiToken.issue(user: current_user, name: api_token_params[:name])
      if @api_token.persisted?
        response.headers["Cache-Control"] = "no-store"
        render :created
      else
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      current_user.api_tokens.find(params[:id]).destroy!
      redirect_to admin_api_tokens_path, notice: "API token was revoked."
    end

    private

    def api_token_params
      params.require(:api_token).permit(:name)
    end
  end
end
