class CardTemplatesController < ApplicationController
  before_action :set_card_template, only: [:show, :edit, :update, :destroy]

  # GET /card_templates
  # GET /card_templates.json
  def index
    @card_templates = CardTemplate.all
  end

  # GET /card_templates/1
  # GET /card_templates/1.json
  def show
  end

  # GET /card_templates/new
  def new
    @card_template = CardTemplate.new
  end

  # GET /card_templates/1/edit
  def edit
  end

  # POST /card_templates
  # POST /card_templates.json
  def create
    @card_template = CardTemplate.new(card_template_params)

    respond_to do |format|
      if @card_template.save
        format.html { redirect_to @card_template, notice: 'Card template was successfully created.' }
        format.json { render :show, status: :created, location: @card_template }
      else
        format.html { render :new }
        format.json { render json: @card_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /card_templates/1
  # PATCH/PUT /card_templates/1.json
  def update
    respond_to do |format|
      if @card_template.update(card_template_params)
        format.html { redirect_to @card_template, notice: 'Card template was successfully updated.' }
        format.json { render :show, status: :ok, location: @card_template }
      else
        format.html { render :edit }
        format.json { render json: @card_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /card_templates/1
  # DELETE /card_templates/1.json
  def destroy
    @card_template.destroy
    respond_to do |format|
      format.html { redirect_to card_templates_url, notice: 'Card template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_card_template
      @card_template = CardTemplate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def card_template_params
      params.require(:card_template).permit(:name)
    end
end
