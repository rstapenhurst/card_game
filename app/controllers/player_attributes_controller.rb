class PlayerAttributesController < ApplicationController
  before_action :set_player_attribute, only: [:show, :edit, :update, :destroy]

  # GET /player_attributes
  # GET /player_attributes.json
  def index
    @player_attributes = PlayerAttribute.all
  end

  # GET /player_attributes/1
  # GET /player_attributes/1.json
  def show
  end

  # GET /player_attributes/new
  def new
    @player_attribute = PlayerAttribute.new
  end

  # GET /player_attributes/1/edit
  def edit
  end

  # POST /player_attributes
  # POST /player_attributes.json
  def create
    @player_attribute = PlayerAttribute.new(player_attribute_params)

    respond_to do |format|
      if @player_attribute.save
        format.html { redirect_to @player_attribute, notice: 'Player attribute was successfully created.' }
        format.json { render :show, status: :created, location: @player_attribute }
      else
        format.html { render :new }
        format.json { render json: @player_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /player_attributes/1
  # PATCH/PUT /player_attributes/1.json
  def update
    respond_to do |format|
      if @player_attribute.update(player_attribute_params)
        format.html { redirect_to @player_attribute, notice: 'Player attribute was successfully updated.' }
        format.json { render :show, status: :ok, location: @player_attribute }
      else
        format.html { render :edit }
        format.json { render json: @player_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /player_attributes/1
  # DELETE /player_attributes/1.json
  def destroy
    @player_attribute.destroy
    respond_to do |format|
      format.html { redirect_to player_attributes_url, notice: 'Player attribute was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player_attribute
      @player_attribute = PlayerAttribute.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_attribute_params
      params.require(:player_attribute).permit(:player, :key, :value)
    end
end
