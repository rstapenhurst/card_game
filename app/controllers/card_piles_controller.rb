class CardPilesController < ApplicationController
  before_action :set_card_pile, only: [:show, :edit, :update, :destroy]

  # GET /card_piles
  # GET /card_piles.json
  def index
    @card_piles = CardPile.all
  end

  # GET /card_piles/1
  # GET /card_piles/1.json
  def show
  end

  # GET /card_piles/new
  def new
    @card_pile = CardPile.new
  end

  # GET /card_piles/1/edit
  def edit
  end

  # POST /card_piles
  # POST /card_piles.json
  def create
    @card_pile = CardPile.new(card_pile_params)

    respond_to do |format|
      if @card_pile.save
        format.html { redirect_to @card_pile, notice: 'Card pile was successfully created.' }
        format.json { render :show, status: :created, location: @card_pile }
      else
        format.html { render :new }
        format.json { render json: @card_pile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /card_piles/1
  # PATCH/PUT /card_piles/1.json
  def update
    respond_to do |format|
      if @card_pile.update(card_pile_params)
        format.html { redirect_to @card_pile, notice: 'Card pile was successfully updated.' }
        format.json { render :show, status: :ok, location: @card_pile }
      else
        format.html { render :edit }
        format.json { render json: @card_pile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /card_piles/1
  # DELETE /card_piles/1.json
  def destroy
    @card_pile.destroy
    respond_to do |format|
      format.html { redirect_to card_piles_url, notice: 'Card pile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_card_pile
      @card_pile = CardPile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def card_pile_params
      params.require(:card_pile).permit(:name)
    end
end
