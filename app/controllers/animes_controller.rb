class AnimesController < ApplicationController
  before_action :set_anime, only: [:show, :edit, :update, :destroy]
  before_action :user_signed_in?, only: [:new, :edit, :update, :destroy]
  before_action :authorized_admin, only: [:admin]

  # GET /animes
  # GET /animes.json
  def index
    @animes = Anime.all
    @current_season_animes = Anime.order('premiered DESC').page.per(4)
    @most_reviewed_animes = @animes.sort_by{|anime| -anime.reviews.count}
    @reivews = Review.all.order(:created_at => :desc)
    @top_airing_animes = Anime.select_top_airing
    @top_upcoming_animes = Anime.select_top_upcoming
  end

  # GET /animes/1
  # GET /animes/1.json
  def show
    @list_animes = Anime.all.order(:score => :desc)
    @add = @anime.adds.includes(:user)
    @is_added = @anime.is_added(current_user)
    @review = Review.new
  end

  # GET /animes/new
  def new
    @anime = Anime.new
  end

  # GET /animes/1/edit
  def edit
  end

  # POST /animes
  # POST /animes.json
  def create
    @anime = Anime.new(anime_params)

    respond_to do |format|
      if @anime.save
        format.html { redirect_to @anime, notice: 'Anime was successfully created.' }
        format.json { render :show, status: :created, location: @anime }
      else
        format.html { render :new }
        format.json { render json: @anime.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /animes/1
  # PATCH/PUT /animes/1.json
  def update
    respond_to do |format|
      if @anime.update(anime_params)
        format.html { redirect_to @anime, notice: 'Anime was successfully updated.' }
        format.json { render :show, status: :ok, location: @anime }
      else
        format.html { render :edit }
        format.json { render json: @anime.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /animes/1
  # DELETE /animes/1.json
  def destroy
    @anime.destroy
    respond_to do |format|
      format.html { redirect_to animes_url, notice: 'Anime was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def anime_list
    if params[:season]
      @current_season = params[:season]
    else
      @current_season = Date.today.to_seasons
    end
    @animes = Anime.all.select{|anime| anime.premiered.to_seasons == @current_season}
    @animes = Kaminari.paginate_array(@animes).page params[:page]
  end

  def top
    # @animes = Anime.page params[:page]
    @most_reviewed_animes = Anime.all
    @most_reviewed_animes = @most_reviewed_animes.sort_by{|anime| -anime.reviews.count}
    @most_reviewed_animes = Kaminari.paginate_array(@most_reviewed_animes).page(params[:page])
  end

  def anime_airing_rank_list
    # Query DB in here
    @animes = Anime.select_top_airing

    @animes.each_with_index do |anime, index|
      if current_user
        anime.check_added = anime.is_added(current_user)
        obj = anime.get_score_from_user(current_user)
        if obj
          anime.review_score = obj.review_score
        else
          anime.review_score = nil
        end
      else
        anime.check_added = nil
        anime.review_score = nil
      end
    end
    @animes = @animes.page params[:page]
  end

  def anime_upcoming_rank_list
    # Query DB in here
    @animes = Anime.select_top_upcoming
    @animes.each_with_index do |anime, index|
      if current_user
        anime.check_added = anime.is_added(current_user)
        obj = anime.get_score_from_user(current_user)
        if obj
          anime.review_score = obj.review_score
        else
          anime.review_score = nil
        end
      else
        anime.check_added = nil
        anime.review_score = nil
      end
    end
    @animes = @animes.page params[:page]
  end

  def admin
    @animes = Anime.all
  end

  def authorized_admin
    if !user_signed_in?
      flash[:alert] = "Please log in."
      redirect_to new_user_session_path
    else
      redirect_to(root_url) unless current_user.role == "admin"
    end
  end

  def sort_by_score
    @q = Anime.ransack(params[:q])
    @search_animes = @q.result(distinct: true).order(:score => :desc).page params[:page]
    @count = @q.result(distinct: true).count
    render "static_pages/result"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_anime
      @anime = Anime.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def anime_params
      params.require(:anime).permit(:name, :kind, :producer, :licencer, :episode, :premiered, :studio, :source, :genre, :duration, :picture, :rating, :score, :description)
    end
end
