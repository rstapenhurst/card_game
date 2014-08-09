class CardAttributesController < ApplicationController
  before_action :set_card_attribute, only: [:show, :edit, :update, :destroy]

  # GET /card_attributes
  # GET /card_attributes.json
  def index
    @card_attributes = CardAttribute.all
  end

  # GET /card_attributes/1
  # GET /card_attributes/1.json
  def show
  end

  # GET /card_attributes/new
  def new
    @card_attribute = CardAttribute.new
  end

  # GET /card_attributes/1/edit
  def edit
  end

  # POST /card_attributes
  # POST /card_attributes.json
  def create
    @card_attribute = CardAttribute.new(card_attribute_params)

    respond_to do |format|
      if @card_attribute.save
        format.html { redirect_to @card_attribute, notice: 'Card attribute was successfully created.' }
        format.json { render :show, status: :created, location: @card_attribute }
      else
        format.html { render :new }
        format.json { render json: @card_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /card_attributes/1
  # PATCH/PUT /card_attributes/1.json
  def update
    respond_to do |format|
      if @card_attribute.update(card_attribute_params)
        format.html { redirect_to @card_attribute, notice: 'Card attribute was successfully updated.' }
        format.json { render :show, status: :ok, location: @card_attribute }
      else
        format.html { render :edit }
        format.json { render json: @card_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /card_attributes/1
  # DELETE /card_attributes/1.json
  def destroy
    @card_attribute.destroy
    respond_to do |format|
      format.html { redirect_to card_attributes_url, notice: 'Card attribute was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_card_attribute
      @card_attribute = CardAttribute.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def card_attribute_params
      params.require(:card_attribute).permit(:card_template_id, :key, :value, :attribute_order)
    end
end
